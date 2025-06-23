import React, { useEffect, useState, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { gsap } from 'gsap';
import api from '../../api';
import esp32qrcode from '../../assets/icons/rickroll.png';
import './RegisterESP32.css';

const RegisterESP32: React.FC = () => {
  const [esp32Id, setEsp32Id] = useState('');
  const [error, setError] = useState('');
  const qrCodeRef = useRef<HTMLDivElement | null>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const id_product = location.state?.id_product;

  useEffect(() => {
    if (!id_product) {
      setError('Produto não especificado.');
    }
  }, [id_product]);

  useEffect(() => {
    initAnimations();

    if (qrCodeRef.current) {
      const scanner = new Html5QrcodeScanner(
        "qrCodeScanner",
        { fps: 10, qrbox: 250 },
        false
      );

      scanner.render(onScanSuccess, onScanError);

      return () => {
        scanner.clear().catch((err) => console.error('Erro ao limpar scanner:', err));
      };
    }
  }, []);

  const initAnimations = () => {
    gsap.from(".brand-section", { duration: 1, x: -100, opacity: 0 });
    gsap.from(".esp32-form-container", { duration: 1, scale: 0.5, opacity: 0 });
    gsap.from(".floating-icon", {
      duration: 1,
      y: -50,
      opacity: 0,
      stagger: 0.2
    });
  };

  const onScanSuccess = (decodedText: string, decodedResult: any) => {
    setEsp32Id(decodedText);
  };

  const onScanError = (error: any) => {
    console.error(`Erro no scanner QR: ${error}`);
  };

  const handleRegister = async () => {
    if (!id_product) {
      setError('Produto não especificado.');
      return;
    }

    if (!esp32Id) {
      setError('O ESP32 ID é obrigatório ou não foi lido corretamente do QR Code.');
      return;
    }

    try {
      await api.post('Products/owned', {
        id_product,
        esp32_unique_id: esp32Id,
      });

      navigate('/specificPurchasedProduct', { state: { id_product } });
    } catch (err) {
      setError('Falha ao registrar o dispositivo. O mesmo pode já estar cadastrado.');
      console.error(err);
    }
  };

  return (
    <div className="register-esp32-container">
      <div className="floating-elements">
        <div className="floating-icon icon-1">📱</div>
        <div className="floating-icon icon-2">🔗</div>
        <div className="floating-icon icon-3">📡</div>
      </div>

      <div className="right-section">
        <div className="brand-section">
          <div className="logo">Ark One</div>
          <h1 className="brand-title">Registro de Dispositivo</h1>
          <p className="brand-subtitle">
            Conecte seu ESP32 à nossa plataforma
          </p>
          <img src={esp32qrcode} alt="ESP32 QR Code" className="esp32-qr-image" />
          <div className="features-list">
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Conexão segura</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Monitoramento em tempo real</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Controle total</span>
            </div>
          </div>
        </div>
      </div>

      <div className="left-section">
        <div className="esp32-form-container">
          <div className="form-header">
            <h2 className="form-title">Registrar ESP32</h2>
            <p className="form-subtitle">Escaneie o QR Code do seu dispositivo</p>
          </div>

          <div className="qr-scanner-container">
            <div
              id="qrCodeScanner"
              ref={qrCodeRef}
              style={{ width: '100%', height: 'auto' }}
            ></div>
          </div>

          <input
            type="text"
            className="form-input"
            placeholder="ESP32 ID"
            value={esp32Id}
            onChange={(e) => setEsp32Id(e.target.value)}
          />

          {error && (
            <div className="error-message">{error}</div>
          )}

          <button className="register-btn" onClick={handleRegister}>
            Registrar Dispositivo
          </button>
        </div>
      </div>
    </div>
  );
};

export default RegisterESP32;
