import React, { useState, useEffect } from 'react';
import { Container, TextField, Button, Typography, Box, Select, MenuItem, InputLabel, FormControl } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';

const RegisterCategory: React.FC = () => {
  const [categoryName, setCategoryName] = useState('');
  const [categoryDescription, setCategoryDescription] = useState('');
  const [idFatherCategory, setIdFatherCategory] = useState<number | ''>(''); 
  const [categories, setCategories] = useState<any[]>([]);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const fetchCategories = async () => {
    try {
      const response = await api.get('/Category/get_all');
      if (response.data.status[0] === 'success') {
        setCategories(response.data.data);
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!categoryName || !categoryDescription) {
      setError('Nome e descrição da categoria são obrigatórios.');
      return;
    }

    try {
      const response = await api.post('/Category/create', {
        category_name: categoryName,
        category_description: categoryDescription,
        id_father_category: idFatherCategory ? idFatherCategory : 0,
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
    <Container maxWidth="xs">
      <Box 
        textAlign="center" 
        mt={5} 
        sx={{
          backgroundColor: 'rgba(255, 255, 255, 0.6)', 
          borderRadius: 2,
          padding: 4,
          boxShadow: 10,
          color: 'black'
        }}
      >
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Criar Categoria
        </Typography>

        <TextField 
          label="Nome da Categoria" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={categoryName} 
          onChange={(e) => setCategoryName(e.target.value)} 
          error={!!error}
          onFocus={() => setError('')}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />

        <TextField 
          label="Descrição da Categoria" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={categoryDescription} 
          onChange={(e) => setCategoryDescription(e.target.value)} 
          error={!!error}
          onFocus={() => setError('')}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />

        <FormControl fullWidth margin="normal">
          <InputLabel id="father-category-label">Subcategoria de</InputLabel>
          <Select
            labelId="father-category-label"
            value={idFatherCategory}
            onChange={(e) => setIdFatherCategory(e.target.value ? Number(e.target.value) : '')}
            label="Categoria Pai"
            color="primary"
            sx={{
              backgroundColor: 'rgba(255, 255, 255, 0.8)', 
              borderRadius: 1,
              '.MuiSelect-icon': { color: 'black' },
            }}
          >
            <MenuItem value="">
              <em>É Categoria Raiz</em>
            </MenuItem>
            {categories.map((category) => (
              <MenuItem key={category.id_category} value={category.id_category}>
                {category.category_name}
              </MenuItem>
            ))}
          </Select>
        </FormControl>

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
          Criar Categoria
        </Button>
      </Box>
    </Container>
  );
};

export default RegisterCategory;
