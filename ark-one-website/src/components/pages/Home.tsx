import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { setUserName } from '../../auth';
import { gsap } from 'gsap';
import './Home.css';

const Home: React.FC = () => {
  const navigate = useNavigate();

  useEffect(() => {
    // Clear any stored username so NavBar doesn't show it when returning to Home
    try { setUserName(null); } catch (e) { /* ignore */ }
    initAnimations();
  }, []);

  const initAnimations = () => {
    // Initial setup - invisible elements
    gsap.set([".hero-title", ".hero-subtitle", ".hero-description", ".cta-buttons"], {
      opacity: 0,
      y: 50
    });

    gsap.set([".logo", ".nav-buttons"], {
      opacity: 0,
      y: -30
    });

    gsap.set(".floating-icon", {
      opacity: 0,
      scale: 0
    });

    gsap.set(".shape", {
      scale: 0,
      rotation: 45
    });

    // Main timeline
    const tl = gsap.timeline();

    // Header animation
    tl.to([".logo", ".nav-buttons"], {
      opacity: 1,
      y: 0,
      duration: 1,
      ease: "power3.out",
      stagger: 0.2
    });

    // Background shapes animation
    tl.to(".shape", {
      scale: 1,
      rotation: 0,
      duration: 1.5,
      ease: "elastic.out(1, 0.5)",
      stagger: 0.1
    }, "-=0.5");

    // Main content animation
    tl.to([".hero-title", ".hero-subtitle", ".hero-description", ".cta-buttons"], {
      opacity: 1,
      y: 0,
      duration: 1,
      ease: "power3.out",
      stagger: 0.2
    }, "-=0.8");

    // Floating icons animation
    tl.to(".floating-icon", {
      opacity: 1,
      scale: 1,
      duration: 0.8,
      ease: "back.out(1.7)",
      stagger: 0.15
    }, "-=0.5");

    startContinuousAnimations();
  };

  const startContinuousAnimations = () => {
    // Continuous animations for shapes and icons
    gsap.to(".shape", {
      rotation: 360,
      duration: 20,
      repeat: -1,
      ease: "none",
      stagger: {
        each: 5,
        from: "random"
      }
    });

    gsap.to(".floating-icon", {
      y: -20,
      duration: 2,
      repeat: -1,
      yoyo: true,
      ease: "power2.inOut",
      stagger: 0.3
    });
  };

  return (
    <div className="home-container">
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
        <div className="shape shape-4"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">⚡</div>
        <div className="floating-icon icon-2">🚀</div>
        <div className="floating-icon icon-3">✨</div>
        <div className="floating-icon icon-4">💫</div>
      </div>

      <main className="main-content">
        <section className="hero-section">
          <h1 className="hero-title">Bem-vindo ao Ark One</h1>
          <h2 className="hero-subtitle">Conecte-se, Explore, Transforme</h2>
          <p className="hero-description">
            Descubra uma nova maneira de interagir com energia solar.
            Nossa plataforma oferece experiências únicas e inovadoras para
            elevar seu potencial ao próximo nível.
          </p>
            <div className="cta-buttons">
            <button className="btn btn-primary cta-btn pulse" onClick={() => navigate('/register')}>
              Começar Agora
            </button>
            <button className="btn btn-secondary cta-btn" onClick={() => navigate('/login')}>
              Fazer Login
            </button>
          </div>
        </section>
      </main>
    </div>
  );
};

export default Home;
