import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { gsap } from 'gsap';
import api from '../../api';
import './Register.css';

const Register: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
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
      await api.post('Account/register', { name, email, password });
      gsap.to(".register-form-container", {
        scale: 0.95,
        duration: 0.3,
        ease: "power2.out",
        onComplete: () => {
          navigate('/login');
        }
      });
    } catch (error) {
      setError('Falha no registro. O email pode já estar em uso.');
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
          <h1 className="brand-title">Junte-se a Nós</h1>
          <p className="brand-subtitle">
            Comece sua jornada de inovação em energia solar hoje
          </p>
          <div className="features-list">
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Cadastro rápido e seguro</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Acesso a produtos exclusivos</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Suporte personalizado</span>
            </div>
            <div className="feature-item">
              <div className="feature-icon">✓</div>
              <span>Atualizações em tempo real</span>
            </div>
          </div>
        </div>
      </div>

      <div className="left-section">
        <div className="register-form-container">
          <div className="form-header">
            <h2 className="form-title">Criar Conta</h2>
            <p className="form-subtitle">Preencha seus dados para começar</p>
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

            {error && (
              <div className="error-message">{error}</div>
            )}

            <button type="submit" className="register-btn" disabled={loading}>
              {loading ? 'Registrando...' : 'Criar Conta'}
              {loading && <div className="loading"></div>}
            </button>

            <div className="divider">
              <span>ou</span>
            </div>

            <div className="login-link">
              Já tem uma conta? <Link to="/login">Entre aqui</Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Register;
