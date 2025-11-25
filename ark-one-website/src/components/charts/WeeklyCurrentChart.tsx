import React, { useEffect, useState } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import api from '../../api';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

interface WeeklyCurrentChartProps {
  esp32_unique_id: string;
}

const WeeklyCurrentChart: React.FC<WeeklyCurrentChartProps> = ({ esp32_unique_id }) => {
  const [data, setData] = useState<Array<any> | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    const fetchData = async () => {
      setLoading(true);
      setData(null);
      try {
        const res = await api.get(`Statistics/solar_tracker/weekly/minmax?esp32_unique_id=${encodeURIComponent(esp32_unique_id)}`);
        if (!mounted) return;
        if (res.data && res.data.status && res.data.status[0] === 'success' && res.data.data && Array.isArray(res.data.data.weekly)) {
          const mapped = res.data.data.weekly.map((r: any) => ({ day: r.day_date, max: Number(r.max_current), min: Number(r.min_current) }));
          setData(mapped);
        } else {
          setData([]);
        }
      } catch (err) {
        console.error('Erro fetching weekly minmax:', err);
        if (mounted) setData([]);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    fetchData();
    return () => { mounted = false; };
  }, [esp32_unique_id]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height={200}>
        <CircularProgress />
      </Box>
    );
  }

  if (!data || data.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height={200}>
        <Typography variant="body2">Nenhum dado semanal disponível.</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h6" sx={{ color: 'black', mb: 2 }}>
        Variação da Corrente Semanal
      </Typography>
      <Box sx={{ width: '100%', height: 260 }}>
        <ResponsiveContainer>
          <BarChart data={data} margin={{ top: 10, right: 20, left: 0, bottom: 5 }} barGap={-20} barCategoryGap="20%">
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="day" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="max" fill="#388e3c" barSize={20} />
            <Bar dataKey="min" fill="#ffb74d" barSize={14} />
          </BarChart>
        </ResponsiveContainer>
      </Box>
    </Box>
  );
};

export default WeeklyCurrentChart;
