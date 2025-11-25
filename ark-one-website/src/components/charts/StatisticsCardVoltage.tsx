import React, { useEffect, useState, useCallback } from 'react';
import { Box, CircularProgress, Typography, Grid } from '@mui/material';
import api from '../../api';

interface StatisticsCardProps {
  esp32_unique_id: string;
}

const StatisticsCard: React.FC<StatisticsCardProps> = ({ esp32_unique_id }) => {
  const [statistics, setStatistics] = useState<any>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchStatisticsData = useCallback(async () => {
    try {
      // clear previous statistics immediately to avoid showing stale data when switching devices
      setStatistics(null);
      setLoading(true);
      const response = await api.get(`Statistics/solar_tracker/today/summary?esp32_unique_id=${encodeURIComponent(esp32_unique_id)}`);
      
      if (response.data && response.data.status && response.data.status[0] === 'success' && response.data.data && Array.isArray(response.data.data.summary) && response.data.data.summary.length > 0) {
        setStatistics(response.data.data.summary[0]);
      } else {
        setStatistics(null);
      }
      setLoading(false);
    } catch (error) {
      console.error("Erro ao buscar as estatísticas:", error);
      setStatistics(null);
      setLoading(false);
    }
  }, [esp32_unique_id]);  

  useEffect(() => {
    // initial fetch and polling every 5 seconds; also re-runs when esp32_unique_id changes via fetchStatisticsData dependency
    fetchStatisticsData();
    const intervalId = setInterval(fetchStatisticsData, 5000);
    return () => {
      clearInterval(intervalId);
    };
  }, [fetchStatisticsData]);  

  return (
    <Box
      borderRadius={2}
      padding={4}
      height="300px"
      sx={{
        backgroundColor: 'rgba(255, 255, 255, 0.9)',
        boxShadow: 0,
        fontFamily: 'Arial, sans-serif',
        color: '#333'
      }}
    >
      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" height="100%">
          <CircularProgress />
        </Box>
      ) : statistics ? (
        <Grid container spacing={1}>
          <Grid item xs={12} sm={6}>
            <Box sx={{ p: 1.25, borderRadius: 2, background: 'linear-gradient(90deg,#fff7ed,#fff4e6)', border: '1px solid rgba(248,87,0,0.08)' }}>
              <Typography variant="caption" sx={{ color: '#F57C00', fontWeight: 600 }}>Média</Typography>
              <Typography variant="h6" sx={{ fontWeight: 700, color: '#333' }}>{(statistics.MeanVoltages ?? 0).toFixed(2)} V</Typography>
            </Box>
          </Grid>
          
          <Grid item xs={12} sm={6}>
            <Box sx={{ p: 1.25, borderRadius: 2, background: 'linear-gradient(90deg,#f0f8ff,#eef7ff)', border: '1px solid rgba(30,136,229,0.06)' }}>
              <Typography variant="caption" sx={{ color: '#1976d2', fontWeight: 600 }}>Mediana</Typography>
              <Typography variant="h6" sx={{ fontWeight: 700, color: '#333' }}>{(statistics.MedianVoltages ?? 0).toFixed(2)} V</Typography>
            </Box>
          </Grid>

          <Grid item xs={12} sm={6}>
            <Box sx={{ p: 1.25, borderRadius: 2, background: 'linear-gradient(90deg,#fff8e1,#fff4d6)', border: '1px solid rgba(255,193,7,0.06)' }}>
              <Typography variant="caption" sx={{ color: '#f9a825', fontWeight: 600 }}>Desvio Padrão</Typography>
              <Typography variant="h6" sx={{ fontWeight: 700, color: '#333' }}>{(statistics.SDVoltages ?? 0).toFixed(2)}</Typography>
            </Box>
          </Grid>

          <Grid item xs={12} sm={6}>
            <Box sx={{ p: 1.25, borderRadius: 2, background: 'linear-gradient(90deg,#f5f5ff,#efefff)', border: '1px solid rgba(103,58,183,0.04)' }}>
              <Typography variant="caption" sx={{ color: '#5e35b1', fontWeight: 600 }}>Assimetria</Typography>
              <Typography variant="h6" sx={{ fontWeight: 700, color: '#333' }}>{(statistics.SkewnessVoltages ?? 0).toFixed(2)}</Typography>
            </Box>
          </Grid>
        </Grid>
       ) : (
         <Typography variant="body2" color="black">Nenhuma estatística disponível.</Typography>
       )}
     </Box>
   );
 };

 export default StatisticsCard;