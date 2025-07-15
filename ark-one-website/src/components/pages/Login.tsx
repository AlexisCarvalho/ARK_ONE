import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { gsap } from 'gsap';
import api from '../../api';
import { setAuthToken } from '../../auth';
import './Login.css';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    initAnimations();
  }, []);

  const initAnimations = () => {
    gsap.from(".brand-section", { duration: 1, x: 100, opacity: 0 }); // Changed from -100 to 100
    gsap.from(".login-form-container", { duration: 1, scale: 0.5, opacity: 0 });
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

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (!email || !password) {
      setError('Por favor, preencha todos os campos');
      setLoading(false);
      return;
    }

    try {
      const response = await api.post('Account/login', { email, password });
      setAuthToken(response.data.data.token);
      gsap.to(".login-form-container", {
        scale: 0.95,
        duration: 0.3,
        ease: "power2.out",
        onComplete: () => {
          navigate('/productList');
        }
      });
    } catch (error) {
      setError('Login falhou. Senha ou Email Incorretos.');
      gsap.to(".login-form-container", {
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
    <div className="login-container">
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
        <div className="shape shape-4"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">🔐</div>
        <div className="floating-icon icon-2">⚡</div>
        <div className="floating-icon icon-3">✨</div>
      </div>

      <div className="left-section">
        <div className="brand-section">
          <div className="logo">Ark One</div>
          <h1 className="brand-title">Conecte-se ao Futuro</h1>
          <p className="brand-subtitle">
            Acesse sua conta e continue sua jornada de transformação digital
          </p>
          <div className="features-list">
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Acesso seguro e criptografado</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Interface intuitiva e moderna</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Experiência personalizada</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Suporte 24/7 disponível</span>
            </div>
          </div>
        </div>
      </div>

      <div className="right-section">
        <div className="login-form-container">
          <div className="form-header">
            <h2 className="form-title">Bem-vindo de volta!</h2>
            <p className="form-subtitle">Entre na sua conta para continuar</p>
          </div>

          <form onSubmit={handleLogin}>
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

            <div className="form-options">
              <div className="checkbox-container">
                <input type="checkbox" id="remember" />
                <label htmlFor="remember">Lembrar de mim</label>
              </div>
              <a href="#" className="forgot-password">Esqueceu a senha?</a>
            </div>

            {error && (
              <div className="error-message">{error}</div>
            )}

            <button type="submit" className="login-btn" disabled={loading}>
              {loading ? 'Entrando...' : 'Entrar'}
              {loading && <div className="loading"></div>}
            </button>

            <div className="divider">
              <span>ou</span>
            </div>

            <div className="signup-link">
              Não tem uma conta? <Link to="/register">Cadastre-se aqui</Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
