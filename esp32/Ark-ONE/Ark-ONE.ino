/* #################################################################################################################################################
 Projeto de monitoramento solar com controle de servo motor, exibição de ângulo solar, e leitura de dados de sensores.
 
 - O sistema calcula e ajusta o ângulo de um servo motor com base no ângulo de elevação solar.
 - Utiliza um sensor de corrente (ACS712) para medir a corrente elétrica, um sensor de tensão para medir a voltagem e calcula a potência gerada.
 - Os dados de temperatura (DS18B20), juntamente com os valores de tensão, corrente e potência, são exibidos em uma tela TFT com interface gráfica.
 - O ângulo solar é calculado em tempo real, e o servo motor e a interface gráfica ajustam suas posições com base nesse cálculo.
 - O projeto também envia os dados via serial e HTTP para uma API, permitindo a visualização em tempo real no monitor serial ou em um site.
 - Inclui uma interface de controle para resetar e atualizar as informações exibidas.

################################################################################################################################################# */

// Bibliotecas padrão do ESP32 e C++
#include <Wire.h>
#include <SPI.h>
#include <cmath>
// Biblioteca necessária para obter o ID do chip e temperatura interna
#include <esp_system.h>
// Bibliotecas para controle da tela TFT e touchscreen
#include <TFT_eSPI.h>
#include <XPT2046_Touchscreen.h>
// Bibliotecas para dispositivos de hardware específicos
#include <RTClib.h>
#include <ESP32Servo.h>
// Bibliotecas para conectividade Wi-Fi
#include <WiFi.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
// Bibliotecas para sensor de temperatura DS18B20
#include <OneWire.h>
#include <DallasTemperature.h>

// Definições e constantes
#define TFT_GREY 0x5AEB
#define TFT_LGREY 0xF7BE
#define TFT_DBLUE 0x2005
#define TFT_LBLUE 0x5C1F
#define TFT_DORANGE 0xF300
#define TFT_LCYAN 0x1F76
#define PINO_TERMOMETRO 17
#define TOUCH_CS 16
#define TOUCH_IRQ 27
#define LOOP_PERIOD 5000
#define servoPin 13
#define pinCorrente 34
#define pinTensao 35
#define refTensao 3.3
#define sensibilidade 0.066
#define fatorDivisor 7.57

// Objetos
OneWire oneWire(PINO_TERMOMETRO);
DallasTemperature sensors(&oneWire);
TFT_eSPI tft = TFT_eSPI();
XPT2046_Touchscreen touch(TOUCH_CS, TOUCH_IRQ);
RTC_DS3231 rtc;
Servo myServo;
WiFiManager wm;
HTTPClient http;

// Variáveis de estado
float angle;
int servoAngle;
int value[3] = { 0, 0, 0 };
int old_value[3] = { -1, -1, -1 };
int old_analog = -999;
float ltx = 0;
uint16_t osx = 120, osy = 120;
uint32_t updateTime = 0;
bool Day, DayCicle, showAngles = false;
float minElevation, maxElevation;
float previousElevationAngle = 0;
float previousServoAngle = 0;
float temperatura;
const float latitude = -22.587238634005907;
const float longitude = -44.962614164254965;
const char *Rapi_url = "http://192.168.53.229:8000/ESP32_DataEntry/receive_data/solar_panel";
const char *Sapi_url = "http://192.168.53.229:8000/ESP32_DataEntry/send_data/solar_panel";

String getChipID() {
  uint64_t chipID = ESP.getEfuseMac();
  String id = String((uint32_t)(chipID >> 32), HEX) + String((uint32_t)chipID, HEX);
  return id;  // ID unico do ESP
}

float getChipTemperature() {
  return temperatureRead();  // Lê a temperatura interna
}

int getDayOfYear(DateTime now) {
  // Recebe dados do dia e mês para calcular o dia do ano
  int day = now.day();      // Extrai o dia do objeto 'now' (representando a data atual)
  int month = now.month();  // Extrai o mês do objeto 'now'

  // Define um array com o número de dias em cada mês
  // Verifica se o ano é bissexto (se divisível por 4 e não divisível por 100, ou divisível por 400)
  // Se for bissexto, fevereiro tem 29 dias, caso contrário, 28
  int daysInMonth[] = { 31, 28 + (now.year() % 4 == 0 && (now.year() % 100 != 0 || now.year() % 400 == 0)), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

  // Variável para armazenar o dia do ano
  int dayOfYear = 0;

  // Calcula a soma dos dias dos meses anteriores ao mês atual
  for (int i = 0; i < month - 1; i++) {
    dayOfYear += daysInMonth[i];
  }

  // Adiciona o dia do mês atual ao total, obtendo o dia do ano
  dayOfYear += day;

  return dayOfYear;  // Retorna o dia do ano
}

float calcElevationAngle(float latitude, float longitude, int hour, int minute, int dayOfYear) {
  // Calcula a hora decimal (hora + minutos convertidos para fração de hora, ajustados com o fuso horário)
  float decimalHour = hour + minute / 60.0;

  // Calcula o ângulo de declinação solar (variação do ângulo do sol ao longo do ano)
  // O valor 23.45 é a máxima inclinação da Terra em relação ao plano da órbita
  // O termo (284 + dayOfYear) / 365.0 ajusta o ângulo de declinação para o dia do ano
  float declinationAngle = 23.45 * sin(2 * PI * (284 + dayOfYear) / 365.0) * PI / 180.0;

  // Calcula o tempo solar, ajustando para o fuso horário e longitude
  float solarTime = decimalHour + (4 * (longitude - 15 * round(longitude / 15))) / 60.0;

  // Calcula o ângulo horário, que depende da diferença entre o tempo solar e o meio-dia
  // O valor 15 é a quantidade de graus por hora em que o sol se move ao longo do dia
  float hourAngle = (solarTime - 12) * 15 * PI / 180.0;

  // Converte a latitude de graus para radianos
  float latitudeRad = latitude * PI / 180.0;

  // Calcula o ângulo de elevação solar utilizando a fórmula trigonométrica
  // A fórmula leva em conta a declinação solar, a latitude do local e o ângulo horário
  float elevationAngle = asin(sin(declinationAngle) * sin(latitudeRad) + cos(declinationAngle) * cos(latitudeRad) * cos(hourAngle));

  // Converte o ângulo de elevação de radianos para graus
  elevationAngle = elevationAngle * 180.0 / PI;

  // Retorna o ângulo de elevação solar
  return elevationAngle;
}

float termopar() {
  // Solicita a leitura das temperaturas de todos os sensores conectados
  sensors.requestTemperatures();

  // Obtém a temperatura do primeiro sensor (índice 0) em graus Celsius
  float temperatura = sensors.getTempCByIndex(0);

  // Cria um buffer para armazenar a string formatada com a temperatura
  char tempBuf[15];

  // Formata a string com a temperatura, limitando a 2 casas decimais
  snprintf(tempBuf, sizeof(tempBuf), "Temp: %.2f C", temperatura);

  // Define a cor do texto (texto cinza sobre fundo cinza claro) para o display TFT
  tft.setTextColor(TFT_GREY, TFT_LGREY);

  // Exibe a string formatada no display TFT, alinhada à direita nas coordenadas (225, 270)
  // O número '2' representa o tamanho da fonte
  tft.drawRightString(tempBuf, 225, 270, 2);

  // Retorna a temperatura medida pelo termômetro
  return temperatura;
}

void findMinMaxElevation(float latitude, float longitude, int dayOfYear, float &minElevation, float &maxElevation) {
  // Inicializa os valores de minElevation e maxElevation com os limites possíveis
  // O ângulo mínimo é inicialmente 90° (sol no horizonte) e o máximo é -90° (sol abaixo do horizonte)
  minElevation = 90.0;
  maxElevation = -90.0;

  // Loop pelas horas de 4:00 a 14:00 (horário solar, por exemplo, do amanhecer até o início da tarde)
  for (int hour = 4; hour <= 14; ++hour) {
    // Loop pelos minutos de cada hora (0 a 59)
    for (int minute = 0; minute < 60; ++minute) {
      // Calcula o ângulo de elevação solar para a hora, minuto e dia do ano fornecidos
      float elevationAngle = calcElevationAngle(latitude, longitude, hour, minute, dayOfYear);

      // Se o ângulo de elevação for positivo (sol acima do horizonte) e menor que o mínimo atual, atualiza o mínimo
      if (elevationAngle >= 0 && elevationAngle < minElevation) minElevation = elevationAngle;

      // Se o ângulo de elevação for maior que o máximo atual, atualiza o máximo
      if (elevationAngle > maxElevation) maxElevation = elevationAngle;
    }
  }
}

void connectWiFi() {
  // Configura o modo do ESP32 para o modo "Station" (WIFI_STA), ou seja, ele se conecta a uma rede Wi-Fi
  WiFi.mode(WIFI_STA);

  // Tenta se conectar automaticamente a uma rede Wi-Fi com o nome "ARK_ONE" e senha "admONEux"
  if (!wm.autoConnect("ARK_ONE", "admONEux")) {
    // Se a conexão falhar, imprime uma mensagem de erro no monitor serial
    Serial.println("Failed to connect");

    // Reinicia o ESP32 em caso de falha na conexão
    ESP.restart();
  }

  // Se a conexão for bem-sucedida, imprime uma mensagem indicando que a conexão foi estabelecida
  Serial.println("Conectado ao WiFi");
}

void initializeScreen() {
  // Inicializa o display TFT
  tft.init();

  // Define a rotação da tela para 180 graus (valor 2 pode representar 180 graus dependendo do modelo da tela)
  tft.setRotation(2);

  // Inicializa o módulo de toque (touchscreen)
  touch.begin();

  // Define a rotação do touchscreen para 180 graus, alinhando com a rotação do display
  touch.setRotation(2);
}

void setupScreenDisplay() {
  // Preenche a tela com a cor azul claro (TFT_LCYAN)
  tft.fillScreen(TFT_LCYAN);
  delay(200);

  // **Frame 1:**
  // Externo - círculo maior de cor branca (círculo principal)
  tft.fillCircle(120, 159, 50, TFT_WHITE);
  // Externo - círculo menor de cor azul claro (círculo interno)
  tft.fillCircle(120, 159, 30, TFT_LCYAN);
  // Barra central (retângulo) de cor azul claro
  tft.fillRect(107, 90, 28, 70, TFT_LCYAN);
  // Interno - círculo superior de cor branca
  tft.fillCircle(120, 104, 10, TFT_WHITE);
  // Interno - círculo inferior de cor branca
  tft.fillCircle(120, 139, 10, TFT_WHITE);
  // Interno - barra central (retângulo) de cor branca
  tft.fillRect(111, 105, 20, 35, TFT_WHITE);
  delay(300);

  // **Frame 2:**
  // Externo - círculo menor de cor azul claro
  tft.fillCircle(120, 159, 20, TFT_LCYAN);
  // Barra central (retângulo) de cor azul claro
  tft.fillRect(107, 90, 28, 70, TFT_LCYAN);
  // Interno - círculo superior de cor branca
  tft.fillCircle(120, 110, 10, TFT_WHITE);
  // Interno - círculo inferior de cor branca
  tft.fillCircle(120, 145, 10, TFT_WHITE);
  // Interno - barra central (retângulo) de cor branca
  tft.fillRect(111, 111, 20, 35, TFT_WHITE);
  delay(70);

  // **Frame 3:**
  // Externo - círculo menor de cor azul claro
  tft.fillCircle(120, 160, 14, TFT_LCYAN);
  // Barra central (retângulo) de cor azul claro
  tft.fillRect(107, 90, 28, 70, TFT_LCYAN);
  // Interno - círculo superior de cor branca
  tft.fillCircle(120, 113, 10, TFT_WHITE);
  // Interno - círculo inferior de cor branca
  tft.fillCircle(120, 151, 10, TFT_WHITE);
  // Interno - barra central (retângulo) de cor branca
  tft.fillRect(111, 114, 20, 38, TFT_WHITE);
  delay(70);

  // **Frame 4:**
  // Externo - círculo menor de cor azul claro
  tft.fillCircle(120, 160, 12, TFT_LCYAN);
  // Barra central (retângulo) de cor azul claro
  tft.fillRect(109, 90, 24, 70, TFT_LCYAN);
  // Interno - círculo superior de cor branca
  tft.fillCircle(120, 116, 10, TFT_WHITE);
  // Interno - círculo inferior de cor branca
  tft.fillCircle(120, 155, 10, TFT_WHITE);
  // Interno - barra central (retângulo) de cor branca
  tft.fillRect(111, 117, 20, 39, TFT_WHITE);
  delay(70);

  // **Frame 5 até Frame 10:**
  // Cria círculos de tamanhos crescentes, com cada tela exibindo um círculo maior em branco
  tft.fillCircle(120, 159, 50, TFT_WHITE);  // Frame 5
  delay(70);

  tft.fillCircle(120, 159, 65, TFT_WHITE);  // Frame 6
  delay(70);

  tft.fillCircle(120, 159, 85, TFT_WHITE);  // Frame 7
  delay(70);

  tft.fillCircle(120, 159, 110, TFT_WHITE);  // Frame 8
  delay(70);

  tft.fillCircle(120, 159, 135, TFT_WHITE);  // Frame 9
  delay(70);

  tft.fillCircle(120, 159, 160, TFT_WHITE);  // Frame 10
  delay(70);

  // **Frame 11:**
  // Preenche a tela inteira com a cor branca
  tft.fillScreen(TFT_WHITE);
  delay(300);
}

void desenharMedidores() {
  // Desenha os retângulos e círculos para o painel de medidores
  // Desenha um retângulo grande de cor cinza claro (TFT_LGREY)
  tft.fillRect(124, 181, 112, 105, TFT_LGREY);
  tft.fillRect(129, 176, 102, 115, TFT_LGREY);
  tft.fillCircle(129, 181, 5, TFT_LGREY);
  tft.fillCircle(230, 181, 5, TFT_LGREY);
  tft.fillCircle(129, 285, 5, TFT_LGREY);
  tft.fillCircle(230, 285, 5, TFT_LGREY);

  // Chama a função plotLinear para desenhar indicadores para "V" (voltagem), "A" (amperagem), e "W" (potência)
  plotLinear("V", 4, 152);   // Indicador para voltagem "V" na posição (4, 152)
  plotLinear("A", 44, 152);  // Indicador para amperagem "A" na posição (44, 152)
  plotLinear("W", 84, 152);  // Indicador para potência "W" na posição (84, 152)
}

void setup() {
  // Inicializa a comunicação serial a 115200 bps para depuração
  Serial.begin(115200);

  // Conecta o ESP32 à rede Wi-Fi usando a função connectWiFi()
  connectWiFi();

  // Inicializa a tela TFT e configura a rotação
  initializeScreen();

  // Preenche a tela com o layout e os gráficos iniciais
  setupScreenDisplay();

  // Chama a função que desenha os medidores na tela
  desenharMedidores();

  // Inicializa o sensor de temperatura DS18B20
  sensors.begin();

  // Configuração inicial para comunicação HTTP com a API
  http.begin(Rapi_url);                                // Inicia a conexão com a API usando a URL definida
  http.addHeader("Content-Type", "application/json");  // Adiciona o cabeçalho para enviar dados no formato JSON

  // Configura a data, hora, latitude e longitude obtidas da API
  getDataApi();

  // Inicializa o servo motor e configura o ângulo inicial
  myServo.attach(servoPin);           // Define o pino do servo
  myServo.write(previousServoAngle);  // Move o servo para o ângulo anterior armazenado

  // Inicializa a comunicação I2C para o RTC
  Wire.begin(21, 22);  // Define os pinos SDA e SCL para a comunicação I2C

  // Verifica se o módulo RTC (DS3231) está conectado corretamente
  if (!rtc.begin()) {
    Serial.println("RTC não encontrado");
    while (1)  // Se o RTC não for encontrado, entra em um loop infinito
      ;
  }

  // Obtém a data e hora atuais do RTC
  DateTime now = rtc.now();

  // Calcula a elevação mínima e máxima do sol com base na data atual e nas coordenadas
  findMinMaxElevation(latitude, longitude, getDayOfYear(now), minElevation, maxElevation);

  // Armazena o tempo atual em millis para controle de temporização
  updateTime = millis();
}

void loop() {
  // Atualiza a data e hora a partir do RTC (Real Time Clock)
  DateTime now = rtc.now();
  int dayOfYear = getDayOfYear(now);  // Obtém o número do dia do ano
  exibirRelogio(now);                 // Exibe a hora atual na tela

  // Exibe o status de conexão com o Wi-Fi na tela
  exibirStatusWiFi();

  // Atualiza a tela, dependendo da hora do dia (dia/noite)
  atualizarTela(angle);

  // Verifica o toque na tela para ajustar o horário ou exibir ângulos
  processarToque();

  // Chama a função para calcular os valores dos sensores
  calcularSensores();

  // Obtém a temperatura da placa solar (utilizando o termopar)
  float temperatura = termopar();

  // Atualiza os valores mostrados dos sensores na tela
  atualizarMostradorSensores();

  // Atualiza a exibição dos dados a cada ciclo
  if (millis() > updateTime) {            // Verifica se o tempo de atualização foi alcançado
    updateTime = millis() + LOOP_PERIOD;  // Atualiza o tempo de referência

    // Calcula o ângulo de elevação solar com base na hora atual e no dia do ano
    float elevationAngle = calcElevationAngle(latitude, longitude, now.hour(), now.minute(), dayOfYear);
    atualizarAnguloServo(elevationAngle);  // Ajusta o ângulo do servo motor de acordo com o ângulo de elevação

    float chipTemperature = getChipTemperature();

    // Exibe os dados no console serial para depuração
    dataPlotter(elevationAngle, dayOfYear, temperatura, chipTemperature);
  }

  // Aguarda 30ms antes de repetir o ciclo
  delay(30);
}

void exibirRelogio(DateTime now) {
  char dateBuf[11];                                                        // Criação de um buffer de caracteres para armazenar a data no formato DD/MM/AAAA
  sprintf(dateBuf, "%02d/%02d/%04d", now.day(), now.month(), now.year());  // Preenche o buffer 'dateBuf' com a data no formato "DD/MM/AAAA"
  tft.setTextColor(TFT_GREY, TFT_LGREY);                                   // Define a cor do texto e o fundo da tela para exibir a data
  tft.drawRightString(dateBuf, 230, 180, 2);                               // Exibe a data no canto direito da tela (coordenadas 230, 180) com um tamanho de fonte 2

  char timeBuf[6];                                          // Criação de um buffer de caracteres para armazenar a hora no formato HH:MM
  sprintf(timeBuf, "%02d:%02d", now.hour(), now.minute());  // Preenche o buffer 'timeBuf' com a hora no formato "HH:MM"
  tft.drawRightString(timeBuf, 230, 197, 2);                // Exibe a hora no canto direito da tela (coordenadas 230, 197) com um tamanho de fonte 2
}

void exibirStatusWiFi() {
  // Verifica se o WiFi está conectado
  if (WiFi.status() == WL_CONNECTED) {
    String ssidString = WiFi.SSID();                       // Se o WiFi está conectado, armazena o nome da rede SSID
    tft.setTextColor(TFT_LCYAN, TFT_LGREY);                // Define a cor do texto como Cyan claro (TFT_LCYAN) e o fundo como Cinza claro (TFT_LGREY)
    tft.drawRightString(ssidString.c_str(), 230, 235, 2);  // Exibe o nome da rede (SSID) no canto direito da tela, com tamanho de fonte 2
  } else {
    tft.setTextColor(TFT_RED, TFT_LGREY);                          // Caso o WiFi não esteja conectado, define o texto com cor vermelha (TFT_RED)
    tft.drawRightString("Falha na Conexao!", 230, 235, 2);         // Exibe a mensagem de erro "Falha na Conexao!" no canto direito da tela
    tft.drawRightString("Reinicie seu Dispositivo", 230, 254, 2);  // Exibe a sugestão "Reinicie seu Dispositivo" um pouco abaixo
  }
  tft.setTextColor(TFT_GREY, TFT_LGREY);              // Define a cor do texto como cinza (TFT_GREY) para exibir a label "Nome da Rede:"
  tft.drawRightString("Nome da Rede:", 230, 216, 2);  // Exibe o texto "Nome da Rede:" no canto direito da tela, com tamanho de fonte 2
}

void atualizarTela(float angle) {
  // Verifica se o valor do ângulo está dentro do intervalo que representa o dia (entre -85 e 85 graus)
  bool novoPeriodo = (angle > -85 && angle <= 85);

  // Verifica se houve mudança entre os períodos (dia/noite)
  if (Day != novoPeriodo) {
    // Atualiza o estado do período (dia ou noite)
    Day = novoPeriodo;

    // Define a cor de fundo com base no período (dia ou noite)
    uint16_t corFundo = Day ? TFT_LBLUE : TFT_DBLUE;

    // Preenche o fundo com a cor correspondente ao período
    tft.fillRect(0, 0, 240, 141, corFundo);  // Preenche a parte superior da tela
    tft.fillRect(6, 141, 228, 6, corFundo);  // Preenche a linha de separação entre as seções
    tft.fillCircle(5, 141, 5, corFundo);     // Desenha um círculo no canto inferior esquerdo
    tft.fillCircle(234, 141, 5, corFundo);   // Desenha um círculo no canto inferior direito

    // Se for dia, desenha a agulha do sol
    if (Day) {
      plotNeedle(0, 0);  // Função para desenhar o ponteiro do sol
    } else {
      // Se for noite, desenha a lua
      tft.fillCircle(208, 29, 18, TFT_ORANGE);  // Desenha o corpo da lua
      tft.fillCircle(200, 35, 15, TFT_DBLUE);   // Desenha a sombra da lua, criando efeito de fase
      plotNeedle(30, 0);                        // Função para desenhar o ponteiro da lua
    }
  }
}

void processarToque() {
  // Desenha o botão na tela
  drawButton();

  // Verifica se há toque na tela
  if (touch.touched()) {
    // Obtém a posição do toque
    TS_Point p = touch.getPoint();

    // Mapeia as coordenadas do toque para o tamanho da tela
    int16_t xtc = map(p.x, 320, 3800, 0, tft.width());
    int16_t ytc = map(p.y, 220, 3800, 0, tft.height());

    // Verifica se o toque ocorreu na área do botão para exibir/ocultar ângulos
    if (xtc > 121 && xtc < 240 && ytc > 292 && ytc < 320) {
      delay(50);  // Pequeno delay para evitar toques múltiplos
      // Altera o fundo da tela conforme o período (dia/noite)
      uint16_t corFundo = Day ? TFT_LBLUE : TFT_DBLUE;
      tft.fillRect(0, 0, 240, 141, corFundo);  // Preenche a parte superior da tela
      tft.fillRect(6, 141, 228, 6, corFundo);  // Preenche a linha de separação
      tft.fillCircle(5, 141, 5, corFundo);     // Círculo no canto inferior esquerdo
      tft.fillCircle(234, 141, 5, corFundo);   // Círculo no canto inferior direito

      // Alterna a exibição de ângulos na tela
      showAngles = !showAngles;
      plotNeedle(angle - 1, 0);  // Atualiza a agulha com o novo valor de ângulo
    }
    // Verifica se o toque foi no botão de reset
    else if (xtc > 121 && xtc < 178 && ytc > 150 && ytc < 176) {
      delay(20);      // Pequeno delay para evitar toques múltiplos
      ESP.restart();  // Reinicia o dispositivo
    }
    // Verifica se o toque foi no botão de atualizar
    else if (xtc > 183 && xtc < 240 && ytc > 150 && ytc < 176) {
      // Chama a função para obter dados da API
      delay(20);     // Pequeno delay para evitar toques múltiplos
      getDataApi();  // Puxa dados e atualiza o RTC
    }
  }
}

void getDataApi() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String url = "http://192.168.53.229:8000/ESP32_DataEntry/receive_data/solar_panel?esp32_unique_id=" + String(getChipID());
    
    // Iniciar a requisição GET
    http.begin(url);
    int httpResponseCode = http.GET();
    String payload = http.getString();

    if (httpResponseCode == 200) {
      Serial.println("Resposta da API: " + payload);

      // Extrair os dados do JSON da resposta
      DynamicJsonDocument doc(1024);
      DeserializationError error = deserializeJson(doc, payload);

      if (error) {
        Serial.print("Erro ao desserializar JSON: ");
        Serial.println(error.f_str());
        return;
      }

      // Obter os valores dos arrays
      int year = doc["year"][0];
      int month = doc["month"][0];
      int day = doc["day"][0];
      int hour = doc["hour"][0];
      int minute = doc["minute"][0];
      float second = doc["second"][0];
      float latitude = doc["latitude"][0];
      float longitude = doc["longitude"][0];

      // Ajustar o RTC
      rtc.adjust(DateTime(year, month, day, hour, minute, (int)second));
      Serial.println("RTC atualizado com sucesso!");
    } else {
      Serial.print("Erro na requisição: ");
      Serial.println(httpResponseCode);
      Serial.println("Resposta da API (erro): " + payload);
    }

    http.end();
  } else {
    Serial.println("Erro de conexão Wi-Fi");
  }
}

void atualizarAnguloServo(float elevationAngle) {
  // Compara o novo ângulo de elevação com o anterior
  if (elevationAngle > previousElevationAngle) {
    // Se o novo ângulo for maior, o ângulo na tela é mapeado de -90 a 0
    // O ângulo do servo é mapeado de 0 a 90
    angle = map(elevationAngle, minElevation, maxElevation, -90, 0);      // ângulo na tela
    servoAngle = map(elevationAngle, minElevation, maxElevation, 0, 90);  // ângulo do servo
    Serial.println("angulo subindo");                                     // Indica que o ângulo está subindo
  } else if (elevationAngle < previousElevationAngle) {
    // Se o novo ângulo for menor, o ângulo na tela é mapeado de 90 a 0
    // O ângulo do servo é mapeado de 180 a 90
    angle = map(elevationAngle, minElevation, maxElevation, 90, 0);         // ângulo na tela
    servoAngle = map(elevationAngle, minElevation, maxElevation, 180, 90);  // ângulo do servo
    Serial.println("angulo descendo");                                      // Indica que o ângulo está descendo
  } else {
    Serial.println("angulo estatico");  // Indica que o ângulo está estático
  }

  // Limita o ângulo do servo dentro dos valores definidos
  servoAngle = constrain(servoAngle, 30, 150);

  // Movimento gradual do servo, caso o novo ângulo seja diferente do anterior
  if (servoAngle != previousServoAngle) {
    // Se o novo ângulo do servo for maior que o anterior, move o servo gradualmente para cima
    if (servoAngle > previousServoAngle) {
      for (float pos = previousServoAngle; pos <= servoAngle; pos++) {
        myServo.write(pos);  // Move o servo para a posição 'pos'
        delay(50);           // Espera 50 ms antes de mover o servo para a próxima posição
      }
    } else {  // Se o novo ângulo do servo for menor que o anterior, move o servo gradualmente para baixo
      for (float pos = previousServoAngle; pos >= servoAngle; pos--) {
        myServo.write(pos);  // Move o servo para a posição 'pos'
        delay(50);           // Espera 50 ms antes de mover o servo para a próxima posição
      }
    }
  }

  // Atualiza os valores anteriores do servo e do ângulo de elevação
  previousServoAngle = servoAngle;
  previousElevationAngle = elevationAngle;
}

void calcularSensores() {
  // Realiza a filtragem e calcula a corrente diretamente
  // 'filtro()' é uma função que retorna um sinal filtrado do sensor (valor do ADC)
  int sinalSensor = filtro();  // Leitura do sinal do sensor após filtragem

  // Calcula a corrente (usando a fórmula apropriada para o sensor)
  // O valor do sinal é ajustado para corresponder à faixa de corrente, considerando a referência do sensor
  float corrente = (sinalSensor - 2.048) * (3.300) / (4095.0 * sensibilidade);
  // '2.048' é o valor de referência do sensor, '3.300' é a tensão de referência do ADC,
  // '4095' é o valor máximo do ADC de 12 bits, e 'sensibilidade' é uma constante do sensor.

  // Leitura e cálculo da tensão
  // A função 'analogRead' lê o valor de tensão do pino especificado (pinTensao)
  float leituraTensao = analogRead(pinTensao);  // Leitura do valor do ADC para a tensão
  // Calcula a tensão real utilizando o valor da referência de tensão ('refTensao') e o divisor de tensão ('fatorDivisor')
  float tensao = (leituraTensao * refTensao) / 4095.0 * fatorDivisor;
  // 'refTensao' é a referência de tensão do ADC, '4095' é o valor máximo do ADC de 12 bits,
  // e 'fatorDivisor' é o fator usado para ajustar a leitura da tensão.

  // Calcula a potência utilizando a fórmula P = V * I (Potência = Tensão * Corrente)
  // A potência é calculada com o valor absoluto da corrente e da tensão para garantir que o valor não seja negativo
  float potencia = abs(corrente * tensao);

  // Armazena os valores de tensão, corrente e potência nos índices correspondentes do array 'value'
  // Estes valores são usados posteriormente em outras partes do código, como para enviar para a API
  value[0] = tensao;    // Armazena o valor da tensão no índice 0
  value[1] = corrente;  // Armazena o valor da corrente no índice 1
  value[2] = potencia;  // Armazena o valor da potência no índice 2
}

void atualizarMostradorSensores() {
  // Chama a função plotPointer() para desenhar o ponteiro
  plotPointer();

  // Verifica se é dia (Day é verdadeiro) ou noite (Day é falso)
  // Se for dia, chama plotNeedle com o valor de 'angle', o ângulo calculado para a tela
  // Se for noite, desenha o ponteiro a 30 graus (posição fixa)
  Day ? plotNeedle(angle, 30) : plotNeedle(30, 0);
}

int filtro() {
  long soma = 0;                    // Variável para armazenar a soma das leituras
  for (int i = 0; i < 1000; i++) {  // Loop de 1000 iterações
    soma += analogRead(A0);         // Lê o valor analógico do pino A0 e adiciona à soma
    delay(1);                       // Pausa de 1 milissegundo entre as leituras
  }
  return soma / 1000;  // Retorna a média das 1000 leituras
}

void drawButton() {
  // angulos
  tft.fillRect(124, 295, 112, 20, showAngles ? TFT_ORANGE : TFT_LCYAN);          // Desenha o botão para "Exibir Angulos?"
  tft.setTextColor(TFT_GREY);                                                    // Cor do texto
  tft.drawString(showAngles ? "   Exibindo!" : "Exibir Angulos?", 133, 297, 2);  // Exibe o texto no botão

  // reset
  tft.fillRect(124, 152, 54, 20, TFT_ORANGE);  // Desenha o botão "Reset"
  tft.setTextColor(TFT_GREY);                  // Cor do texto
  tft.drawString("Reset", 126, 154, 2);        // Exibe o texto no botão "Reset"

  // atualizar
  tft.fillRect(182, 152, 54, 20, TFT_ORANGE);  // Desenha o botão "Atualizar"
  tft.setTextColor(TFT_GREY);                  // Cor do texto
  tft.drawString("Atualizar", 184, 154, 2);    // Exibe o texto no botão "Atualizar"
}

void plotNeedle(int angle, byte ms_delay) {
  // Define a cor do ponteiro dependendo do estado de 'Day'
  uint16_t color = Day ? TFT_LBLUE : TFT_DBLUE;

  // Limita o ângulo entre -80 e 80 graus
  angle = constrain(angle, -80, 80);

  // Atualiza o ponteiro até alcançar o ângulo desejado
  while (old_analog != angle) {
    old_analog += (old_analog < angle) ? 1 : -1;

    // Se ms_delay for 0, move diretamente para o ângulo final
    if (ms_delay == 0) old_analog = angle;

    // Converte o ângulo para coordenadas cartesianas
    float sdeg = map(old_analog, 10, 170, -80, 80);
    float sx = cos(sdeg * DEG_TO_RAD);
    float sy = sin(sdeg * DEG_TO_RAD);

    // Desenha a linha do ponteiro e o círculo na extremidade
    tft.drawLine(120 + 20 * ltx, 140 - 20, osx, osy, color);
    tft.fillCircle(osx, osy, 20, color);

    // Desenha as marcações no mostrador
    for (int i = -90; i < 91; i += 5) {
      tft.setTextColor(TFT_GREY);
      int tl = 15;
      float sx = cos((i - 90) * 0.0174532925);
      float sy = sin((i - 90) * 0.0174532925);
      uint16_t x0 = sx * (100 + tl) + 120;
      uint16_t y0 = sy * (100 + tl) + 140;
      uint16_t x1 = sx * 100 + 120;
      uint16_t y1 = sy * 100 + 140;

      float sx2 = cos((i + 5 - 90) * 0.0174532925);
      float sy2 = sin((i + 5 - 90) * 0.0174532925);
      int x2 = sx2 * (100 + tl) + 120;
      int y2 = sy2 * (100 + tl) + 140;
      int x3 = sx2 * 100 + 120;
      int y3 = sy2 * 100 + 140;

      // Checa se showAngles está ativado para exibir ângulos
      if (showAngles) {
        // Desenha os limites de nascer e por do sol no ângulo
        if (i >= -90 && i < -60) {
          tft.fillTriangle(x0, y0, x1, y1, x2, y2, TFT_DORANGE);
          tft.fillTriangle(x1, y1, x2, y2, x3, y3, TFT_DORANGE);
        }
        if (i >= 60 && i < 90) {
          tft.fillTriangle(x0, y0, x1, y1, x2, y2, TFT_DORANGE);
          tft.fillTriangle(x1, y1, x2, y2, x3, y3, TFT_DORANGE);
        }

        // Desenha as marcas de 5 graus
        if (i % 30 != 0) tl = 5;
        x0 = sx * (100 + tl) + 120;
        y0 = sy * (100 + tl) + 140;
        x1 = sx * 100 + 120;
        y1 = sy * 100 + 140;

        // Desenha as marcações de múltiplos de 30 graus
        tft.drawLine(x0, y0, x1, y1, TFT_GREY);
        if (i % 30 == 0) {
          x0 = sx * (100 + tl + 10) + 120;
          y0 = sy * (100 + tl + 10) + 140;
          switch (i / 30) {
            case -2: tft.drawCentreString("30", x0, y0 - 12, 2); break;
            case -1: tft.drawCentreString("60", x0, y0 - 9, 2); break;
            case 0: tft.drawCentreString("90", x0, y0 - 6, 2); break;
            case 1: tft.drawCentreString("120", x0, y0 - 9, 2); break;
            case 2: tft.drawCentreString("150", x0, y0 - 12, 2); break;
          }
        }
      }

      // Desenha linhas de marcação
      sx = cos((i + 5 - 90) * 0.0174532925);
      sy = sin((i + 5 - 90) * 0.0174532925);
      x0 = sx * 100 + 120;
      y0 = sy * 100 + 140;
      if (i < 90) tft.drawLine(x0, y0 - 1, x1, y1 - 1, TFT_WHITE);
      if (i < 90) tft.drawLine(x0, y0, x1, y1, TFT_WHITE);
      if (i < 90) tft.drawLine(x0, y0 + 1, x1, y1 + 1, TFT_WHITE);
    }

    // Desenha o ponteiro atual baseado no ângulo
    ltx = tan((sdeg + 90) * DEG_TO_RAD);
    osx = sx * 98 + 120;
    osy = sy * 98 + 140;

    // Desenha a linha do ponteiro
    tft.drawLine(120 + 20 * ltx, 140 - 20, osx, osy, color);
    tft.fillCircle(osx, osy, 20, color);

    // Desenha o círculo central para indicar o "pino" do ponteiro
    if (Day) {
      tft.fillCircle(osx, osy, 16, TFT_ORANGE);
    }

    // Desenha nuvens no fundo (para decoração)
    tft.fillCircle(79, 112, 20, TFT_LGREY);
    tft.fillRect(79, 123, 50, 10, TFT_LGREY);
    tft.fillCircle(98, 92, 23, TFT_WHITE);
    tft.fillCircle(128, 112, 20, TFT_WHITE);
    tft.fillCircle(98, 105, 24, TFT_WHITE);

    // Exibe o valor do ângulo perto das nuvens, se 'showAngles' for verdadeiro
    if (showAngles) {
      tft.setTextColor(TFT_GREY, TFT_WHITE);
      char buf[8];
      dtostrf(angle + 90, 4, 1, buf);
      tft.drawRightString(buf, 110, 100, 2);
      tft.setCursor(110, 100);
      tft.print("°");
    }

    // Desenha nuvens (simula o céu durante o dia ou noite)
    if (Day) {
      tft.fillCircle(209, 34, 12, TFT_LGREY);
      tft.fillRect(179, 41, 30, 6, TFT_LGREY);
      tft.fillCircle(197, 22, 14, TFT_WHITE);
      tft.fillCircle(179, 34, 12, TFT_WHITE);
      tft.fillCircle(194, 30, 13, TFT_WHITE);
    } else {
      tft.fillCircle(168, 57, 13, TFT_LGREY);
      tft.fillRect(168, 65, 33, 6, TFT_LGREY);
      tft.fillCircle(179, 45, 15, TFT_WHITE);
      tft.fillCircle(200, 57, 13, TFT_WHITE);
      tft.fillCircle(183, 52, 14, TFT_WHITE);
    }

    // Delay para controlar a velocidade do movimento
    delay(ms_delay);
  }
}

void plotLinear(const char *label, int x, int y) {
  int w = 36;  // Define o comprimento da barra

  // Desenha a base da barra
  tft.fillRect(x + 5, y, w - 10, 164, TFT_LGREY);
  tft.fillRect(x, y + 5, w, 154, TFT_LGREY);

  // Desenha círculos nos cantos da barra para efeito visual
  tft.fillCircle(x + 5, y + 5, 5, TFT_LGREY);
  tft.fillCircle(x + 30, y + 5, 5, TFT_LGREY);
  tft.fillCircle(x + 5, y + 158, 5, TFT_LGREY);
  tft.fillCircle(x + 30, y + 158, 5, TFT_LGREY);

  // Define a cor do texto e desenha o rótulo na parte superior da barra
  tft.setTextColor(TFT_GREY);
  tft.drawCentreString(label, x + w / 2, y + 2, 2);

  // Desenha linhas horizontais para representar a escala na barra
  for (int i = 0; i < 110; i += 10) {
    tft.drawFastHLine(x + 24, y + 36 + i, 6, TFT_GREY);  // Marcas de 10 unidades
  }

  // Desenha linhas horizontais mais largas para as marcas principais
  for (int i = 0; i < 110; i += 50) {
    tft.drawFastHLine(x + 24, y + 36 + i, 9, TFT_GREY);  // Marcas de 50 unidades
  }

  // Desenha um triângulo na parte inferior da barra para indicar um ponto de referência
  tft.fillTriangle(x + 3, y + 127, x + 19, y + 127, x + 3, y + 127 - 5, TFT_LCYAN);  // Triângulo superior
  tft.fillTriangle(x + 3, y + 127, x + 19, y + 127, x + 3, y + 127 + 5, TFT_LCYAN);  // Triângulo inferior
}

void plotPointer() {
  int dy = 187;  // Posição inicial vertical para a linha do ponteiro
  byte pw = 16;  // Largura do ponteiro

  // Define a cor do texto
  tft.setTextColor(TFT_GREY, TFT_LGREY);

  // Laço para desenhar os valores para cada indicador
  for (int i = 0; i < 3; i++) {
    char buf[8];

    // Converte o valor para string e exibe na tela
    dtostrf(value[i], 4, 0, buf);
    tft.drawRightString(buf, i * 39 + 35, 295, 2);

    int dx = 6 + 40 * i;  // Posição horizontal do ponteiro

    // Constrói limites para os valores
    value[i] = constrain(value[i], 0, (i == 2) ? 625 : 25);
    value[i] = map(value[i], 0, (i == 2) ? 625 : 25, 0, 100);  // Mapeia os valores de 0 a 100 ou 0 a 625

    // Laço para desenhar os ponteiros e animar o movimento
    while (old_value[i] != value[i]) {
      dy = 187 + 100 - old_value[i];  // Posição vertical ajustada pelo valor antigo

      // Caso o valor atual seja maior que o anterior, desenha a linha para cima
      if (old_value[i] < value[i]) {
        tft.drawLine(dx, dy + 5, dx + pw, dy, TFT_LGREY);      // Linha em cinza
        old_value[i]++;                                        // Atualiza o valor antigo
        tft.drawLine(dx, dy - 6, dx + pw, dy - 1, TFT_LCYAN);  // Linha em ciano
      }
      // Caso contrário, desenha a linha para baixo
      else {
        tft.drawLine(dx, dy - 5, dx + pw, dy, TFT_LGREY);      // Linha em cinza
        old_value[i]--;                                        // Atualiza o valor antigo
        tft.drawLine(dx, dy + 6, dx + pw, dy + 1, TFT_LCYAN);  // Linha em ciano
      }
    }
  }
}

void dataPlotter(float elevationAngle, int dayOfYear, float temperatura, float chipTemperature) {

  // Exibe os valores de ângulos e outros parâmetros no monitor serial
  Serial.println("Angulo Max:   " + String(maxElevation));     // Exibe o ângulo máximo calculado
  Serial.println("Angulo Min:   " + String(minElevation));     // Exibe o ângulo mínimo calculado
  Serial.println("Angulo Servo: " + String(servoAngle));       // Exibe o ângulo do servo motor
  Serial.println("Angulo Tela:  " + String(angle));            // Exibe o ângulo atual da tela
  Serial.println("Angulo Sol:   " + String(elevationAngle));   // Exibe o ângulo do sol
  Serial.println("Dia Do Ano:   " + String(dayOfYear));        // Exibe o dia do ano
  Serial.println("Temperatura:  " + String(temperatura));      // Exibe a temperatura medida
  Serial.println("Temp Interna: " + String(chipTemperature));  // Exibe a temperatura medida
  Serial.println("ID unico:     " + String(getChipID()));      // Exibe a temperatura medida

  // Exibe os valores dos sensores (tensão, corrente e potência)
  Serial.println("V: " + String(value[0]));  // Tensão
  Serial.println("A: " + String(value[1]));  // Corrente
  Serial.println("W: " + String(value[2]));  // Potência

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(Sapi_url);
    http.addHeader("Content-Type", "application/json");

    // Cria o JSON com os dados
    String jsonData = "{";
    jsonData += "\"esp32_unique_id\":\"" + String(getChipID()) + "\",";
    jsonData += "\"max_elevation\":" + String(maxElevation) + ",";
    jsonData += "\"min_elevation\":" + String(minElevation) + ",";
    jsonData += "\"servo_tower_angle\":" + String(servoAngle) + ",";
    jsonData += "\"solar_panel_temperature\":" + String(temperatura) + ",";
    jsonData += "\"esp32_core_temperature\":" + String(chipTemperature) + ",";
    jsonData += "\"voltage\":" + String(value[0]) + ",";
    jsonData += "\"current\":" + String(value[1]);
    jsonData += "}";

    // Envia a solicitação POST
    int httpResponseCode = http.POST(jsonData);

    // Verifica o código de resposta
    if (httpResponseCode > 0) {
      Serial.println("Dados enviados com sucesso!");
      Serial.println("Código de resposta: " + String(httpResponseCode));
    } else {
      Serial.println("Falha ao enviar dados!");
      Serial.println("Erro: " + String(httpResponseCode));
    }

    // Fecha a conexão
    http.end();
  } else {
    Serial.println("Erro: Não conectado ao WiFi");
  }
}
