import React, { useState } from 'react';
import { AppBar, Toolbar, Tabs, Tab, Box, Grid, Typography, Card, CardContent, Button } from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import RealTimeVoltageChart from './RealTimeVoltageChart';
import RealTimeCurrentChart from './RealTimeCurrentChart';
import RealTimeTemperatureChart from './RealTimeTemperatureChart';
import TodayVoltageChart from './TodayVoltageChart';
import TodayCurrentChart from './TodayCurrentChart';
import StatisticsCard from './StatisticsCard';
import WeeklyVoltageChart from './WeeklyVoltageChart';
import WeeklyCurrentChart from './WeeklyCurrentChart';

const Dashboard: React.FC = () => {
  const [value, setValue] = useState(0);
  const navigate = useNavigate();
  const location = useLocation();
  const { id_product_instance, id_product } = location.state || {};

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  const handleVoltar = async () => {
    navigate('/specificPurchasedProduct', { state: { id_product_instance, id_product } });
  };

  const renderContent = () => {
    switch (value) {
      case 0:
        return (
          <Grid container spacing={3} mt={3}>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Voltagem</Typography>
                  <RealTimeVoltageChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Corrente</Typography>
                  <RealTimeCurrentChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Temperatura</Typography>
                  <RealTimeTemperatureChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );
      case 1:
        return (
          <Grid container spacing={3} mt={3}>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Voltagem de Hoje</Typography>
                  <TodayVoltageChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Corrente de Hoje</Typography>
                  <TodayCurrentChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Estatísticas de Hoje</Typography>
                  <StatisticsCard id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );
      case 2:
        return (
          <Grid container spacing={3} mt={3}>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Voltagem Semanal</Typography>
                  <WeeklyVoltageChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card sx={{ backgroundColor: 'rgba(255, 255, 255, 0.8)', boxShadow: 10, borderRadius: 5 }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Corrente Semanal</Typography>
                  <WeeklyCurrentChart id_product_instance={id_product_instance} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
            </Grid>
          </Grid>
        );
      default:
        return null;
    }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar 
        position="fixed"
        sx={{
          background: 'linear-gradient(90deg, #F85700, #FFA901)',
          boxShadow: 3,
          zIndex: 1100,
        }}
      >
        <Toolbar>
          <Typography variant="h6" sx={{ flexGrow: 1, color: 'white' }}>
            Dashboard
          </Typography>
          <Tabs value={value} onChange={handleChange} textColor="inherit">
            <Tab label="Tempo Real" />
            <Tab label="Diário" />
            <Tab label="Semanal" />
          </Tabs>
          <Button 
            variant="contained" 
            sx={{ 
              ml: 2,
              border: 'none',
              boxShadow: 'none',
              backgroundColor: 'inherit',
              '&:hover': {
                boxShadow: 'none',
                backgroundColor: '#FAA000',
              },
            }}
            onClick={handleVoltar}
          >
            Voltar
          </Button>
        </Toolbar>
      </AppBar>
      <Box sx={{ p: 2, mt: 8 }}>
        {renderContent()}
      </Box>
    </Box>
  );
};

export default Dashboard;