import React, { useEffect, useState, useRef } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';
import api from '../../api';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

interface WeeklyVoltageChartProps {
  esp32_unique_id: string;
}

const WeeklyVoltageChart: React.FC<WeeklyVoltageChartProps> = ({ esp32_unique_id }) => {
  const [data, setData] = useState<Array<any> | null>(null);
  const [loading, setLoading] = useState(true);

  const wrapperRef = useRef<HTMLDivElement | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let mounted = true;
    const fetchData = async () => {
      // reset readiness while fetching new data
      setReady(false);
      setLoading(true);
      setData(null);
      try {
        const res = await api.get(`Statistics/solar_tracker/weekly/minmax?esp32_unique_id=${encodeURIComponent(esp32_unique_id)}`);
        if (!mounted) return;
        if (res.data && res.data.status && res.data.status[0] === 'success' && res.data.data && Array.isArray(res.data.data.weekly)) {
          // Map to chart-friendly format: day (short) and min/max
          const mapped = res.data.data.weekly.map((r: any) => ({ day: r.day_date, max: Number(r.max_voltage), min: Number(r.min_voltage) }));
          setData(mapped);
          // ensure chart renders even if ResizeObserver hasn't reported size yet
          setReady(true);
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

    // observe wrapper size
    const el = wrapperRef.current;
    if (el) {
      const check = () => setReady(el.clientWidth > 0 && el.clientHeight > 0);
      check();
      const ro = new ResizeObserver(check);
      ro.observe(el);
      return () => { mounted = false; ro.disconnect(); };
    }
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
        Variação da Voltagem Semanal
      </Typography>
      <Box sx={{ width: '100%', height: 260 }} ref={wrapperRef}>
        {!ready ? (
          <Box display="flex" alignItems="center" justifyContent="center" height="100%"><Typography variant="body2" sx={{ color: '#666' }}>Aguardando tamanho do contêiner...</Typography></Box>
        ) : (
          <ResponsiveContainer>
            <BarChart data={data} margin={{ top: 10, right: 20, left: 0, bottom: 5 }} barGap={-20} barCategoryGap="20%">
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="day" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="max" fill="#1976d2" barSize={20} />
              <Bar dataKey="min" fill="#ff9800" barSize={14} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </Box>
    </Box>
  );
};

export default WeeklyVoltageChart;
