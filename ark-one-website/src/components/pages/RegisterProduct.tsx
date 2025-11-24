import React, { useState, useEffect } from 'react';
import { Container, TextField, Button, Typography, Box, Select, MenuItem, InputLabel, FormControl, Checkbox, FormControlLabel } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';
import { gsap } from 'gsap';
import './RegisterProduct.css';

const RegisterProduct: React.FC = () => {
  const [productName, setProductName] = useState('');
  const [productDescription, setProductDescription] = useState('');
  const [productPrice, setProductPrice] = useState('');
  const [idCategory, setIdCategory] = useState<string | ''>('');  
  const [locationDependent, setLocationDependent] = useState(false);
  const [categories, setCategories] = useState<any[]>([]);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const fetchCategories = async () => {
    try {
      const response = await api.get('/Categories/get_all');
      if (response.data.status[0] === 'success') {
        // API returns categories under data.categories
        setCategories(response.data.data.categories || []);
      } else {
        setCategories([]);
      }
    } catch (error) {
      console.error('Erro ao buscar categorias:', error);
      setCategories([]);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);
  
  useEffect(() => {
    initAnimations();
  }, []);
  
  const initAnimations = () => {
    gsap.set([".register-product-page .register-product-card"], { opacity: 0, y: 40 });
    gsap.set(".register-product-page .shape", { scale: 0, rotation: 45, opacity: 0 });
    gsap.set(".register-product-page .floating-icon", { opacity: 0, scale: 0 });

    const tl = gsap.timeline();
    // animate scale, rotation and opacity so shapes become visible
    tl.to(".register-product-page .shape", { scale: 1, rotation: 0, opacity: 0.12, duration: 1.2, ease: "elastic.out(1, 0.6)", stagger: 0.1 });
    tl.to(".register-product-page .register-product-card", { opacity: 1, y: 0, duration: 0.8, ease: "power3.out" }, "-=0.6");
    tl.to(".register-product-page .floating-icon", { opacity: 1, scale: 1, duration: 0.8, ease: "back.out(1.7)", stagger: 0.12 }, "-=0.4");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!productName || !productDescription || !productPrice) {
      setError('Nome, descrição e preço são obrigatórios.');
      return;
    }

    try {
      const response = await api.post('/Products/register', {
        product_name: productName,
        product_description: productDescription,
        id_category: idCategory ? idCategory : null,
        location_dependent: locationDependent,
        product_price: productPrice,
      });

      if (response.status === 201) {
        navigate('/productList');
      } else {
        setError('Erro ao criar o produto.');
      }
    } catch (error) {
      console.error('Erro ao criar produto:', error);
      setError('Erro ao criar o produto.');
    }
  };

  return (
    <div className="register-product-page" style={{ position: 'relative', minHeight: '100vh', paddingTop: '94px', background: 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)' }}>
      {/* Background shapes */}
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
      </div>

      {/* Floating icons */}
      <div className="floating-elements">
        <div className="floating-icon icon-1">⚡</div>
        <div className="floating-icon icon-2">🚀</div>
        <div className="floating-icon icon-3">✨</div>
      </div>

      <Container maxWidth="sm" sx={{ position: 'relative', zIndex: 2, pt: 4 }}>
        <Box className="register-product-card" sx={{ backgroundColor: 'rgba(255,255,255,0.9)', borderRadius: 2, p: 4, boxShadow: 10 }}>
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
            Cadastrar Produto
          </Typography>

          <TextField 
            label="Nome do Produto" 
            variant="filled" 
            fullWidth 
            margin="normal" 
            color="primary"
            value={productName} 
            onChange={(e) => setProductName(e.target.value)} 
            error={!!error} 
            onFocus={() => setError('')} 
            sx={{ 
              input: { color: 'black' }, 
              bgcolor: 'rgba(255,255,255,0.8)', 
              borderRadius: 1 
            }}
          />

          <TextField 
            label="Descrição do Produto" 
            variant="filled" 
            fullWidth 
            margin="normal" 
            color="primary"
            value={productDescription} 
            onChange={(e) => setProductDescription(e.target.value)} 
            error={!!error}
            onFocus={() => setError('')}
            sx={{ 
              input: { color: 'black' }, 
              bgcolor: 'rgba(255,255,255,0.8)', 
              borderRadius: 1 
            }}
          />

          <TextField 
            label="Preço do Produto" 
            type="number" 
            variant="filled" 
            fullWidth 
            margin="normal" 
            color="primary"
            value={productPrice} 
            onChange={(e) => setProductPrice(e.target.value)} 
            error={!!error}
            onFocus={() => setError('')}
            sx={{ 
              input: { color: 'black' }, 
              bgcolor: 'rgba(255,255,255,0.8)', 
              borderRadius: 1 
            }}
          />

          <FormControl fullWidth margin="normal">
            <InputLabel id="category-label">Categoria</InputLabel>
            <Select
              labelId="category-label"
              value={idCategory}
              onChange={(e) => {
                const selectedCategory = e.target.value ? String(e.target.value) : '';
                setIdCategory(selectedCategory);
              }}
              label="Categoria"
              color="primary"
              sx={{
                backgroundColor: 'rgba(255,255,255,0.8)', 
                borderRadius: 1,
                '.MuiSelect-icon': { color: 'black' },
              }}
            >
              <MenuItem value="">
                <em>Sem Categoria</em>
              </MenuItem>
              {categories.map((category) => (
                <MenuItem key={category.id_category} value={category.id_category}>
                  {category.category_name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControlLabel
            control={
              <Checkbox
                checked={locationDependent}
                onChange={(e) => setLocationDependent(e.target.checked)}
                name="locationDependent"
                color="primary"
              />
            }
            label="Produto Dependente de Localização"
            sx={{ color: 'black', marginTop: 2 }}
          />

          {error && (
            <Typography variant="body2" color="error" sx={{ mt: 2 }}>
              {error}
            </Typography>
          )}

          <Button 
            variant="contained" 
            fullWidth 
            sx={{ 
              mt: 2, 
              backgroundColor: '#007bff', 
              '&:hover': { backgroundColor: '#0056b3' } 
            }} 
            onClick={handleSubmit}
          >
            Cadastrar Produto
          </Button>
        </Box>
      </Container>
    </div>
  );
};

export default RegisterProduct;
