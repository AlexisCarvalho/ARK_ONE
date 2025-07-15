import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../api';
import gsap from 'gsap';
import './ProductList.css';  // Add this import

interface Product {
  id_product: string;
  product_name: string;
  product_description: string;
  location_dependent: boolean;
  product_price: number;
}

const ProductList: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const containerRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    if (containerRef.current) {
      initAnimations();
      fetchData();
      setupMouseMove();
    }

    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
    };
  }, []);

  const initAnimations = () => {
    gsap.set(".page-header, .products-stats", {
      opacity: 0,
      y: 50
    });

    gsap.set(".logo, .header-actions", {
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

    const tl = gsap.timeline();

    tl.to(".logo, .header-actions", {
      opacity: 1,
      y: 0,
      duration: 1,
      ease: "power3.out",
      stagger: 0.2
    });

    tl.to(".shape", {
      scale: 1,
      rotation: 0,
      duration: 1.5,
      ease: "elastic.out(1, 0.5)",
      stagger: 0.1
    }, "-=0.5");

    tl.to(".page-header", {
      opacity: 1,
      y: 0,
      duration: 1.2,
      ease: "power3.out"
    }, "-=0.8");

    startContinuousAnimations();
  };

  const startContinuousAnimations = () => {
    gsap.to(".shape", {
      rotation: "+=360",
      duration: 25,
      repeat: -1,
      ease: "none",
      stagger: {
        each: 5,
        from: "random"
      }
    });

    gsap.to(".floating-icon", {
      y: "-=20",
      duration: 3,
      repeat: -1,
      yoyo: true,
      ease: "power2.inOut",
      stagger: 0.4
    });
  };

  const handleMouseMove = (e: MouseEvent) => {
    const { clientX, clientY } = e;
    const { innerWidth, innerHeight } = window;
    
    const xPercent = (clientX / innerWidth - 0.5) * 2;
    const yPercent = (clientY / innerHeight - 0.5) * 2;

    gsap.to(".floating-icon", {
      x: xPercent * 10,
      y: yPercent * 10,
      duration: 1,
      ease: "power2.out",
      stagger: 0.1
    });

    gsap.to(".shape", {
      x: xPercent * 15,
      y: yPercent * 15,
      duration: 1.5,
      ease: "power2.out",
      stagger: 0.05
    });
  };

  const setupMouseMove = () => {
    window.addEventListener('mousemove', handleMouseMove);
  };

  const fetchData = async () => {
    setIsLoading(true);
    try {
      await fetchUserType();
      await fetchProducts();
    } finally {
      setIsLoading(false);
    }
  };

  const fetchUserType = async () => {
    try {
      const response = await api.get('/Users/role');
      if (
        response.data.status[0] === 'success' &&
        response.data.data[0].user_role === 'admin'
      ) {
        setIsAdmin(true);
      }
    } catch (error) {
      console.error('Erro ao verificar tipo de usuário:', error);
    }
  };

  const fetchProducts = async () => {
    try {
      const response = await api.get('/Products/get_all');
      
      if (response.status === 204) {
        setProducts([]);
      } else {
        setProducts(response.data.data.products);
      }
    } catch (error) {
      console.error('Erro ao recuperar produtos:', error);
    }
  };

  const handleRegisterNewESP32 = (id_product: string) => {
    navigate('/RegisterESP32', { state: { previousLocation: window.location.pathname, id_product } });
  };

  const handleViewMyProducts = (id_product: string) => {
    navigate('/specificPurchasedProduct', { state: { previousLocation: window.location.pathname, id_product } });
  };

  const handleDeleteProduct = async (id_product: string) => {
    try {
      await api.delete(`/Products/${id_product}`);
      setProducts(products.filter((product) => product.id_product !== id_product));
    } catch (error) {
      console.error('Erro ao deletar produto:', error);
      alert('Erro ao deletar o produto. Tente novamente mais tarde.');
    }
  };

  const renderProducts = () => {
    return products
      .filter(product => 
        product.product_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.product_description.toLowerCase().includes(searchTerm.toLowerCase())
      )
      .map((product) => (
        <div className="product-card" key={product.id_product}>
          <div className="product-header">
            <div className="product-id">{product.id_product}</div>
            <div className={`location-badge ${!product.location_dependent ? 'not-dependent' : ''}`}>
              {product.location_dependent ? '📍 Local' : '🌍 Global'}
            </div>
          </div>
          <h3 className="product-name">{product.product_name}</h3>
          <p className="product-description">{product.product_description}</p>
          <div className="product-footer">
            <div className="product-price">
              <span className="currency">R$</span>
              {product.product_price.toFixed(2)}
            </div>
            <div className="product-actions">
              <button 
                className="add-to-cart-btn"
                onClick={() => handleRegisterNewESP32(product.id_product)}
              >
                Cadastrar Novo
              </button>
              <button 
                className="view-products-btn"
                onClick={() => handleViewMyProducts(product.id_product)}
              >
                Meus Produtos
              </button>
              {isAdmin && (
                <button 
                  className="delete-btn"
                  onClick={() => handleDeleteProduct(product.id_product)}
                >
                  Deletar Produto
                </button>
              )}
            </div>
          </div>
        </div>
      ));
  };

  return (
    <div className="container" ref={containerRef}>
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
        <div className="shape shape-4"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">🛍️</div>
        <div className="floating-icon icon-2">💎</div>
        <div className="floating-icon icon-3">⭐</div>
        <div className="floating-icon icon-4">🎯</div>
      </div>

      <header className="header">
        <div className="logo">ARK ONE</div>
        <div className="header-actions">
          <div className="search-box">
            <div className="search-icon">🔍</div>
            <input 
              type="text" 
              className="search-input" 
              placeholder="Buscar produtos..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </header>

      <main className="main-content">
        <div className="page-header">
          <h1 className="page-title">Nossos Produtos</h1>
          <p className="page-subtitle">
            Descubra nossa seleção exclusiva de produtos premium, cuidadosamente escolhidos para oferecer a melhor experiência
          </p>
        </div>

        {isLoading ? (
          <div className="loading-container">
            <div className="loading-spinner"></div>
          </div>
        ) : products.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📦</div>
            <div className="empty-title">Nenhum produto encontrado</div>
            <div className="empty-subtitle">Tente ajustar seus filtros de busca</div>
          </div>
        ) : (
          <div className="products-grid">
            {renderProducts()}
          </div>
        )}
      </main>
    </div>
  );
};

export default ProductList;
