import React, { useState, useEffect } from 'react';
import { Container, TextField, Button, Typography, Box, Select, MenuItem, InputLabel, FormControl } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';
import { gsap } from 'gsap';
import './RegisterCategory.css';

const RegisterCategory: React.FC = () => {
  const [categoryName, setCategoryName] = useState('');
  const [categoryDescription, setCategoryDescription] = useState('');
  const [idFatherCategory, setIdFatherCategory] = useState<string | ''>(''); 
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
    gsap.set([".register-category-page .register-category-card"], { opacity: 0, y: 40 });
    gsap.set(".register-category-page .shape", { scale: 0, rotation: 45, opacity: 0 });
    gsap.set(".register-category-page .floating-icon", { opacity: 0, scale: 0 });

    const tl = gsap.timeline();
    tl.to(".register-category-page .shape", { scale: 1, rotation: 0, opacity: 0.12, duration: 1.2, ease: "elastic.out(1, 0.6)", stagger: 0.1 });
    tl.to(".register-category-page .register-category-card", { opacity: 1, y: 0, duration: 0.8, ease: "power3.out" }, "-=0.6");
    tl.to(".register-category-page .floating-icon", { opacity: 1, scale: 1, duration: 0.8, ease: "back.out(1.7)", stagger: 0.12 }, "-=0.4");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!categoryName || !categoryDescription) {
      setError('Nome e descrição da categoria são obrigatórios.');
      return;
    }

    try {
      const response = await api.post('/Categories/create', {
        category_name: categoryName,
        category_description: categoryDescription,
        id_father_category: idFatherCategory ? idFatherCategory : null,
      });

      if (response.status === 201) {
        navigate('/registerProduct');
      } else {
        setError('Erro ao criar a categoria.');
      }
    } catch (error) {
      console.error('Erro ao criar categoria:', error);
      setError('Erro ao criar a categoria.');
    }
  };

  return (
    <div className="register-category-page" style={{ position: 'relative', minHeight: '100vh', paddingTop: '94px', background: 'linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%)' }}>
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">⚡</div>
        <div className="floating-icon icon-3">✨</div>
        <div className="floating-icon icon-4">💫</div>
      </div>

      <Container maxWidth="sm" sx={{ position: 'relative', zIndex: 2, pt: 4 }}>
        <Box className="register-category-card" sx={{ backgroundColor: 'rgba(255,255,255,0.9)', borderRadius: 2, p: 4, boxShadow: 10 }}>
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
            Criar Categoria
          </Typography>

          <TextField label="Nome da Categoria" variant="filled" fullWidth margin="normal" color="primary" value={categoryName} onChange={(e) => setCategoryName(e.target.value)} error={!!error} onFocus={() => setError('')} sx={{ input: { color: 'black' }, bgcolor: 'rgba(255,255,255,0.8)', borderRadius: 1 }} />

          <TextField label="Descrição da Categoria" variant="filled" fullWidth margin="normal" color="primary" value={categoryDescription} onChange={(e) => setCategoryDescription(e.target.value)} error={!!error} onFocus={() => setError('')} sx={{ input: { color: 'black' }, bgcolor: 'rgba(255,255,255,0.8)', borderRadius: 1 }} />

          <FormControl fullWidth margin="normal">
            <InputLabel id="father-category-label">Subcategoria de</InputLabel>
            <Select labelId="father-category-label" value={idFatherCategory} onChange={(e) => setIdFatherCategory(e.target.value ? String(e.target.value) : '')} label="Categoria Pai" color="primary" sx={{ backgroundColor: 'rgba(255,255,255,0.8)', borderRadius: 1, '.MuiSelect-icon': { color: 'black' } }}>
              <MenuItem value=""><em>É Categoria Raiz</em></MenuItem>
              {categories.map((category) => (<MenuItem key={category.id_category} value={category.id_category}>{category.category_name}</MenuItem>))}
            </Select>
          </FormControl>

          {error && (<Typography variant="body2" color="error" sx={{ mt: 2 }}>{error}</Typography>)}

          <Button variant="contained" fullWidth sx={{ mt: 2, backgroundColor: '#007bff', '&:hover': { backgroundColor: '#0056b3' } }} onClick={handleSubmit}>Criar Categoria</Button>
        </Box>
      </Container>
    </div>
  );
};

export default RegisterCategory;
