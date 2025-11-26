import React, { useState, useEffect } from 'react';
import { AppBar, Toolbar, Tabs, Tab, Box, Grid, Typography, Card, CardContent, Button, Select, MenuItem, FormControl, InputLabel } from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import { gsap } from 'gsap';
import StatisticsCardVoltage from '../charts/StatisticsCardVoltage';
import StatisticsCardCurrent from '../charts/StatisticsCardCurrent';
import InterativeLineChart from '../charts/InterativeLineChart';
import WeeklyCurrentChart from '../charts/WeeklyCurrentChart';
import './Dashboard.css';
import WeeklyVoltageChart from '../charts/WeeklyVoltageChart';

const Dashboard: React.FC = () => {
  const [value, setValue] = useState(0);
  const navigate = useNavigate();
  const location = useLocation();
  const { id_product_instance, id_product, esp32_unique_id, esp32_unique_ids } = location.state || {};
  const [selectedEsp32, setSelectedEsp32] = useState<string | null>(null);

  const availableIds = React.useMemo(() => {
    if (esp32_unique_ids && esp32_unique_ids.length > 0) return esp32_unique_ids;
    if (esp32_unique_id) return [esp32_unique_id];
    return [] as string[];
  }, [esp32_unique_ids, esp32_unique_id]);

  useEffect(() => {
    if (!selectedEsp32 && availableIds.length > 0) {
      setSelectedEsp32(availableIds[0]);
    }
  }, [availableIds, selectedEsp32]);

  React.useEffect(() => {
    if (esp32_unique_id) {
      setSelectedEsp32(esp32_unique_id);
    } else if (esp32_unique_ids && esp32_unique_ids.length > 0) {
      setSelectedEsp32(esp32_unique_ids[0]);
    }
  }, [esp32_unique_id, esp32_unique_ids]);

  useEffect(() => {
    initAnimations();
  }, []);

  useEffect(() => {
    animateTabContent();
  }, [value]);

  const initAnimations = () => {
    // Animação inicial do header
    gsap.from(".dashboard-appbar", {
      y: -100,
      opacity: 0,
      duration: 1,
      ease: "power3.out"
    });

    // Animação das formas de fundo
    gsap.to(".dashboard-shape", {
      rotation: 360,
      duration: 30,
      repeat: -1,
      ease: "none",
      stagger: {
        each: 7.5,
        from: "random"
      }
    });

    // Animação dos ícones flutuantes
    gsap.to(".dashboard-floating-icon", {
      y: -15,
      duration: 2.5,
      repeat: -1,
      yoyo: true,
      ease: "power2.inOut",
      stagger: 0.4
    });
  };

  const animateTabContent = () => {
    gsap.from(".dashboard-card", {
      opacity: 0,
      y: 30,
      scale: 0.95,
      duration: 0.6,
      ease: "power3.out",
      stagger: 0.1
    });
  };

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
  };

  const handleVoltar = async () => {
    navigate('/specificPurchasedProduct', { state: { id_product_instance, id_product } });
  };

  const renderContent = () => {
    switch (value) {
      case 0:
        const idsList = (esp32_unique_ids && esp32_unique_ids.length > 0)
          ? [...esp32_unique_ids]
          : (esp32_unique_id ? [esp32_unique_id] : []);
        if (selectedEsp32) {
          const reordered = [selectedEsp32, ...idsList.filter(id => id !== selectedEsp32)];
          return (
            <Card className="dashboard-card dashboard-main-card">
              <CardContent>
                <InterativeLineChart esp32_unique_ids={reordered} selectedEsp32={selectedEsp32} />
              </CardContent>
            </Card>
          );
        }
        return (
          <Card className="dashboard-card dashboard-main-card">
            <CardContent>
              <InterativeLineChart esp32_unique_ids={idsList} />
            </CardContent>
          </Card>
        );
      case 1:
        return (
          <Grid container spacing={3} mt={1}>
            <Grid item xs={12} sm={6} md={4}>
              <Card className="dashboard-card">
                <CardContent>
                  <Typography variant="h6" className="dashboard-card-title">
                    📊 Estatísticas de Hoje (Voltagem)
                  </Typography>
                  <StatisticsCardVoltage esp32_unique_id={selectedEsp32 || esp32_unique_id} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card className="dashboard-card">
                <CardContent>
                  <Typography variant="h6" className="dashboard-card-title">
                    ⚡ Voltagem Semanal
                  </Typography>
                  <WeeklyVoltageChart esp32_unique_id={selectedEsp32 || esp32_unique_id || ''} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card className="dashboard-card">
                <CardContent>
                  <Typography variant="h6" className="dashboard-card-title">
                    🔋 Corrente Semanal
                  </Typography>
                  <WeeklyCurrentChart esp32_unique_id={selectedEsp32 || esp32_unique_id || ''} />
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={6} md={4}>
              <Card className="dashboard-card">
                <CardContent>
                  <Typography variant="h6" className="dashboard-card-title">
                    📊 Estatísticas de Hoje (Corrente)
                  </Typography>
                  <StatisticsCardCurrent esp32_unique_id={selectedEsp32 || esp32_unique_id} />
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );
      default:
        return null;
    }
  };

  return (
    <Box className="dashboard-container">
      {/* Background Shapes */}
      <div className="dashboard-background-shapes">
        <div className="dashboard-shape dashboard-shape-1"></div>
        <div className="dashboard-shape dashboard-shape-2"></div>
        <div className="dashboard-shape dashboard-shape-3"></div>
        <div className="dashboard-shape dashboard-shape-4"></div>
      </div>

      {/* Floating Icons */}
      <div className="dashboard-floating-elements">
        <div className="dashboard-floating-icon dashboard-icon-1">⚡</div>
        <div className="dashboard-floating-icon dashboard-icon-2">🔋</div>
        <div className="dashboard-floating-icon dashboard-icon-3">☀️</div>
        <div className="dashboard-floating-icon dashboard-icon-4">📊</div>
      </div>

      {/* AppBar */}
      <AppBar position="fixed" className="dashboard-appbar">
        <Toolbar>
          <Typography variant="h6" className="dashboard-title">
            Dashboard
          </Typography>
          <Tabs 
            value={value} 
            onChange={handleChange} 
            textColor="inherit"
            className="dashboard-tabs"
            TabIndicatorProps={{
              style: { backgroundColor: 'white', height: 3 }
            }}
          >
            <Tab label="Tempo Real" className="dashboard-tab" />
            <Tab label="Global" className="dashboard-tab" />
          </Tabs>
          <FormControl sx={{ ml: 2, minWidth: 160 }} size="small">
            <InputLabel id="select-esp32-label">Dispositivo</InputLabel>
            <Select
              labelId="select-esp32-label"
              value={selectedEsp32 ?? ''}
              label="Dispositivo"
              onChange={(e) => setSelectedEsp32(e.target.value as string)}
              disabled={availableIds.length === 0}
            >
              {availableIds.map((id: string) => (
                <MenuItem key={id} value={id}>{id}</MenuItem>
              ))}
            </Select>
          </FormControl>
           <Button
             variant="contained"
             className="dashboard-back-button"
             onClick={handleVoltar}
           >
             Voltar
           </Button>
        </Toolbar>
      </AppBar>

      {/* Content */}
      <Box className="dashboard-content">
        {renderContent()}
      </Box>
    </Box>
  );
};

export default Dashboard;