import React, { useEffect, useState, useCallback } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import api from '../../api';

interface StatisticsCardProps {
  id_product_instance: number;
}

const StatisticsCard: React.FC<StatisticsCardProps> = ({ id_product_instance }) => {
  const [statistics, setStatistics] = useState<any>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const fetchStatisticsData = useCallback(async () => {
    try {
      setLoading(true);
      const response = await api.get(`Statistics/summary?id_product_instance=${id_product_instance}`);
      
      if (response.data.status[0] === 'success') {
        setStatistics(response.data.data[0]);
      }
      setLoading(false);
    } catch (error) {
      console.error("Erro ao buscar as estatísticas:", error);
      setLoading(false);
    }
  }, [id_product_instance]);  

  useEffect(() => {
    fetchStatisticsData();  
    const interval = setInterval(() => {
      fetchStatisticsData();
    }, 8000);

    return () => clearInterval(interval);
  }, [fetchStatisticsData]);  

  return (
    <Box
      borderRadius={2}
      padding={4}
      height="300px"
      sx={{
        backgroundColor: 'rgba(255, 255, 255, 0.8)',
        boxShadow: 0,
      }}
    >
      {loading ? (
        <Box display="flex" justifyContent="center" alignItems="center" height="100%">
          <CircularProgress />
        </Box>
      ) : statistics ? (
        <Box>
          <Typography variant="body2" color="black">Média de Voltagem: {statistics.MeanVoltages.toFixed(2)} V</Typography>
          <Typography variant="body2" color="black">Mediana de Voltagem: {statistics.MedianVoltages.toFixed(2)} V</Typography>
          <Typography variant="body2" color="black">Desvio Padrão de Voltagem: {statistics.SDVoltages.toFixed(2)} V</Typography>
          <Typography variant="body2" color="black">IQR de Voltagem: {statistics.IQRVoltages.toFixed(2)} V</Typography>
          <Typography variant="body2" color="black">Assimetria de Voltagem: {statistics.SkewnessVoltages.toFixed(2)}</Typography>
          <Typography variant="body2" color="black">Curtose de Voltagem: {statistics.KurtosisVoltages.toFixed(2)}</Typography>
          
          <Typography variant="body2" color="black" sx={{ mt: 2 }}>Média de Corrente: {statistics.MeanCurrents.toFixed(2)} A</Typography>
          <Typography variant="body2" color="black">Mediana de Corrente: {statistics.MedianCurrents.toFixed(2)} A</Typography>
          <Typography variant="body2" color="black">Desvio Padrão de Corrente: {statistics.SDCurrent.toFixed(2)} A</Typography>
          <Typography variant="body2" color="black">IQR de Corrente: {statistics.IQRCurrents.toFixed(2)} A</Typography>
          <Typography variant="body2" color="black">Assimetria de Corrente: {statistics.SkewnessCurrents.toFixed(2)}</Typography>
          <Typography variant="body2" color="black">Curtose de Corrente: {statistics.KurtosisCurrents.toFixed(2)}</Typography>
          
          <Typography variant="body2" color="black" sx={{ mt: 2 }}>Média de Potência: {statistics.MeanWattage.toFixed(2)} W</Typography>
        </Box>
      ) : (
        <Typography variant="body2" color="black">Nenhuma estatística disponível.</Typography>
      )}
    </Box>
  );
};

export default StatisticsCard;
