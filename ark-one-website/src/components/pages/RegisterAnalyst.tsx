import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { gsap } from 'gsap';
import api from '../../api';
import './RegisterAnalyst.css';

const Register: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const userRole = 'analyst';
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    initAnimations();
  }, []);

  const initAnimations = () => {
    gsap.from(".brand-section", { duration: 1, x: -100, opacity: 0 });
    gsap.from(".register-form-container", { duration: 1, scale: 0.5, opacity: 0 });
    gsap.from(".floating-icon", {
      duration: 1,
      y: -50,
      opacity: 0,
      stagger: 0.2
    });
    gsap.from(".shape", {
      duration: 1,
      scale: 0,
      transformOrigin: "center",
      ease: "back.out",
      stagger: 0.2
    });
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (!name || !email || !password) {
      setError('Por favor, preencha todos os campos');
      setLoading(false);
      return;
    }

    try {
      // register specifically as an analyst from this page
      await api.post('Account/register', { name, email, password, user_role: userRole });
      // login to obtain the analyst token
      const loginResp = await api.post('Account/login', { email, password });
      const analystToken = loginResp?.data?.data?.token;
      if (!analystToken) {
        throw new Error('Falha ao obter token do analista');
      }

      // affiliate the newly created analyst to current owner (caller) using the analyst token
      const affiliateResp = await api.post('/Users/affiliate', { token_analyst: analystToken });

      // animate and navigate on success
      gsap.to(".register-form-container", {
        scale: 0.95,
        duration: 0.3,
        ease: "power2.out",
        onComplete: () => {
          navigate('/productList');
        }
      });
    } catch (error) {
      console.error('Erro no registro/afiliação:', error);
      setError('Falha no registro ou afiliação. Verifique os dados e tente novamente.');
      gsap.to(".register-form-container", {
        x: -10,
        duration: 0.1,
        ease: "power2.out",
        yoyo: true,
        repeat: 5
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="register-container">
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
        <div className="shape shape-4"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">📝</div>
        <div className="floating-icon icon-2">⚡</div>
        <div className="floating-icon icon-3">✨</div>
      </div>

      <div className="right-section">
        <div className="brand-section">
          <div className="logo">Ark One</div>
          <h1 className="brand-title">Cadastrar Analista</h1>
          <p className="brand-subtitle">
            Cadastre um analista que poderá visualizar os dados deste moderador em modo leitura.
          </p>
          <div className="features-list">
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Acesso restrito de visualização</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Visualização dos dados do moderador</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Gerenciamento simplificado</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Notificações e relatórios</span>
            </div>
          </div>
        </div>
      </div>

      <div className="left-section">
        <div className="register-form-container">
          <div className="form-header">
            <h2 className="form-title">Cadastrar Analista</h2>
            <div style={{ marginTop: 8, padding: '8px 12px', background: '#f6f7fb', borderRadius: 8, color: '#333' }}>
              Observação: o analista criado terá permissão apenas para visualizar seu dados, não alterá-los.
            </div>
          </div>

          <form onSubmit={handleRegister}>
            <div className="form-group">
              <label className="form-label">Nome</label>
              <input
                type="text"
                className="form-input"
                placeholder="Seu nome completo"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">E-mail</label>
              <input
                type="email"
                className="form-input"
                placeholder="seu@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Senha</label>
              <input
                type="password"
                className="form-input"
                placeholder="Digite sua senha"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            {/* This page always creates an 'analyst' account, so no account type selection is shown */}

            {error && (
              <div className="error-message">{error}</div>
            )}

            <button type="submit" className="register-btn" disabled={loading}>
              {loading ? 'Registrando...' : 'Criar Conta'}
              {loading && <div className="loading"></div>}
            </button>

          </form>
        </div>
      </div>
    </div>
  );
};

export default Register;
