import React, { useEffect, useState, useCallback } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import api from '../../api';

interface TodayVoltageChartProps {
  id_product_instance: number;
}

const TodayVoltageChart: React.FC<TodayVoltageChartProps> = ({ id_product_instance }) => {
  const [imgUrl, setImgUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [previousImgUrl, setPreviousImgUrl] = useState<string | null>(null);

  const fetchGraphData = useCallback(async () => {
    try {
      setLoading(true);

      const response = await api.get(
        `Analytics/generateVoltageZScoreGraph?id_product_instance=${id_product_instance}`,
        { responseType: 'blob' }
      );

      const url = URL.createObjectURL(response.data);

      if (imgUrl) {
        URL.revokeObjectURL(imgUrl);
      }

      setPreviousImgUrl(imgUrl);
      setImgUrl(url);
      setLoading(false);
    } catch (error) {
      console.error("Erro ao buscar dados do gráfico:", error);
      setLoading(false);
    }
  }, [id_product_instance, imgUrl]);

  useEffect(() => {
    fetchGraphData();

    return () => {
      if (imgUrl) {
        URL.revokeObjectURL(imgUrl);
      }
      if (previousImgUrl) {
        URL.revokeObjectURL(previousImgUrl);
      }
    };
  }, [fetchGraphData, imgUrl, previousImgUrl]);

  return (
    <Box>
      <Typography variant="h6" sx={{ color: 'white', mb: 2 }}>
        Variação da Voltagem
      </Typography>
      <Box position="relative" width="100%">
        {imgUrl ? (
          <img
            src={imgUrl}
            alt="Gráfico de Voltagem"
            style={{ width: '100%', height: 'auto' }}
          />
        ) : loading ? (
          <Box display="flex" justifyContent="center" alignItems="center" height="100%">
            <CircularProgress />
          </Box>
        ) : (
          <Typography variant="body2" color="black">
            Nenhum gráfico disponível.
          </Typography>
        )}
      </Box>
    </Box>
  );
};

export default TodayVoltageChart;
