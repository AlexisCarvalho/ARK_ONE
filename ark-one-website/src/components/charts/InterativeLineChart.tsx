import React, { useEffect, useState, useRef } from 'react';
import {
  LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import {
  Container, Button, Box, Stack, Typography,
  Select, MenuItem, InputLabel, FormControl, Checkbox, ListItemText, OutlinedInput
} from '@mui/material';
import dayjs from 'dayjs';

type DeviceDataRow = {
  timestamp: string; 
  max_elevation: number;
  min_elevation: number;
  servo_tower_angle: number;
  solar_panel_temp: number;
  esp32_core_temp: number;
  voltage: number;
  current: number;
};

type DevicePayload = {
  esp32_id: string;
  data: DeviceDataRow[];
};

const ALL_VARIABLES = [
  { key: 'solar_panel_temp', label: 'Solar Panel Temp' },
  { key: 'esp32_core_temp', label: 'ESP32 Core Temp' },
  { key: 'voltage', label: 'Voltage' },
  { key: 'current', label: 'Current' }
];

interface InterativeLineChartProps {
  esp32_unique_ids: string[];
  selectedEsp32?: string;
}

const InteractiveLineChart: React.FC<InterativeLineChartProps> = ({ esp32_unique_ids, selectedEsp32 }) => {
  const [selectedDevice, setSelectedDevice] = useState<string>(
    selectedEsp32 && esp32_unique_ids.includes(selectedEsp32) ? selectedEsp32 : (esp32_unique_ids[0] || '')
  );
  const [selectedVars, setSelectedVars] = useState<string[]>(['solar_panel_temp']);
  const [dataMap, setDataMap] = useState<Record<string, any>>({});
  const [paused, setPaused] = useState(false);
  const [isAreaChart, setIsAreaChart] = useState(false);
  const ws = useRef<WebSocket | null>(null);
  const chartWrapperRef = useRef<HTMLDivElement | null>(null);
  const [chartReady, setChartReady] = useState(false);

  useEffect(() => {
    ws.current = new WebSocket('ws://localhost:8080/ws');

    ws.current.onopen = () => {
      ws.current?.send(JSON.stringify({
        type: 'request_data',
        payload: {
          esp32_ids: esp32_unique_ids
        }
      }));
    };

    return () => {
      ws.current?.close();
    };
  }, []); 

  useEffect(() => {
    if (!ws.current) return;

    const handleMessage = (event: MessageEvent) => {
      if (paused) return;

      try {
        const message = JSON.parse(event.data);
        if (message.type === 'device_data' && Array.isArray(message.data)) {
          const newMap: Record<string, any[]> = { ...dataMap };

          message.data.forEach((device: DevicePayload) => {
            const existing = newMap[device.esp32_id] || [];
            const mapped = (device.data || []).map((entry: any) => ({
              ...entry,
              time: dayjs(entry.created_at || entry.timestamp).format('HH:mm:ss'),
              created_at: entry.created_at || entry.timestamp
            }));
            const combined = [...existing, ...mapped].sort(
              (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
            );
            const grouped: Record<string, any[]> = {};
            combined.forEach(item => {
              if (!grouped[item.time]) grouped[item.time] = [];
              grouped[item.time].push(item);
            });
            const aggregated = Object.entries(grouped).map(([time, items]) => {
              const base = items[0];
              const keys = Object.keys(base).filter(
                k => typeof base[k] === 'number'
              );
              const result: any = { time, created_at: base.created_at };
              keys.forEach(k => {
                result[k] = items.reduce((sum, i) => sum + i[k], 0) / items.length;
              });
              return result;
            });
            const sorted = aggregated.sort(
              (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
            ).slice(-100);
            newMap[device.esp32_id] = sorted;
          });

          setDataMap(newMap);
        }
      } catch (err) {
        console.error('Erro de parsing WebSocket:', err);
      }
    };

    ws.current.onmessage = handleMessage;
  }, [paused]); 

  const currentData = dataMap[selectedDevice] || [];

  const hasData = Array.isArray(currentData) && currentData.length > 0;

  // Keep selectedDevice in sync when props change
  useEffect(() => {
    if (selectedEsp32 && esp32_unique_ids.includes(selectedEsp32)) {
      setSelectedDevice(selectedEsp32);
    } else if (!selectedEsp32 && esp32_unique_ids.length > 0) {
      setSelectedDevice(esp32_unique_ids[0]);
    } else if (esp32_unique_ids.length === 0) {
      setSelectedDevice('');
    }
  }, [esp32_unique_ids, selectedEsp32]);

  useEffect(() => {
    const el = chartWrapperRef.current;
    if (!el) return;
    const check = () => {
      const ok = el.clientWidth > 0 && el.clientHeight > 0;
      setChartReady(ok);
    };
    check();
    const ro = new ResizeObserver(() => check());
    ro.observe(el);
    return () => ro.disconnect();
  }, [/* no deps - wrapper element */]);

  return (
    <Container>
      <Typography variant="h5" gutterBottom>
        Gráfico de Linhas (ESP32)
      </Typography>

      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <FormControl sx={{ minWidth: 250 }}>
           <InputLabel>Variáveis</InputLabel>
           <Select
             multiple
             value={selectedVars}
             onChange={(e) => setSelectedVars(e.target.value as string[])}
             input={<OutlinedInput label="Variáveis" />}
             renderValue={(selected) => selected.join(', ')}
           >
             {ALL_VARIABLES.map(v => (
               <MenuItem key={v.key} value={v.key}>
                 <Checkbox checked={selectedVars.includes(v.key)} />
                 <ListItemText primary={v.label} />
               </MenuItem>
             ))}
           </Select>
         </FormControl>

         <Button
           variant="contained"
           color={paused ? 'success' : 'warning'}
           onClick={() => setPaused(p => !p)}
         >
           {paused ? 'Retomar' : 'Pausar'}
         </Button>
         <Button
           variant="outlined"
           onClick={() => setIsAreaChart(prev => !prev)}
         >
           {isAreaChart ? 'Mostrar Linhas' : 'Mostrar Área'}
         </Button>
       </Stack>

      <Box sx={{ width: '100%', height: 400 }} ref={chartWrapperRef}>
        { !chartReady ? (
          <Box display="flex" alignItems="center" justifyContent="center" height="100%"><Typography variant="body2" sx={{ color: '#666' }}>Aguardando tamanho do contêiner...</Typography></Box>
        ) : (
          <ResponsiveContainer>
          {isAreaChart ? (
            <AreaChart data={currentData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Legend />
              {selectedVars.map((key, index) => (
                <Area
                  key={key}
                  type="monotone"
                  dataKey={key}
                  stroke={['#1976d2', '#ff5722', '#388e3c', '#ff9800'][index % 4]}
                  fill={['#1976d2', '#ff5722', '#388e3c', '#ff9800'][index % 4]}
                  fillOpacity={0.3}
                />
              ))}
            </AreaChart>
          ) : (
            <LineChart data={currentData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Legend />
              {selectedVars.map((key, index) => (
                <Line
                  key={key}
                  type="monotone"
                  dataKey={key}
                  stroke={['#1976d2', '#ff5722', '#388e3c', '#ff9800'][index % 4]}
                  dot={false}
                />
              ))}
            </LineChart>
          )}
          </ResponsiveContainer>
        )}
       </Box>
     </Container>
   );
 };
 
 export default InteractiveLineChart;