import React, { useEffect, useState, useMemo } from 'react';
import { Box, CircularProgress, Typography } from '@mui/material';

interface StatisticsCardProps {
  esp32_unique_id: string;
}

interface ESPDataPoint {
  timestamp: string;
  max_elevation: number;
  min_elevation: number;
  servo_tower_angle: number;
  solar_panel_temperature: number;
  esp32_core_temperature: number;
  voltage: number;
  current: number;
}

const StatisticsCard: React.FC<StatisticsCardProps> = ({ esp32_unique_id }) => {
  const [latestData, setLatestData] = useState<ESPDataPoint | null>(null);
  const [loading, setLoading] = useState(true);

  const ws = useMemo(() => new WebSocket("ws://localhost:8081"), []);

  useEffect(() => {
    ws.onopen = () => {
      ws.send(JSON.stringify({ request_esp32_ids: [esp32_unique_id] }));
    };

    ws.onmessage = (event) => {
      const payload = JSON.parse(event.data);
      if (payload.type === "device_data") {
        const device = payload.data.find((d: any) => d.esp32_id === esp32_unique_id);
        if (device && device.data && device.data.length > 0) {
          const mostRecent = device.data[device.data.length - 1];
          setLatestData(mostRecent);
          setLoading(false);
        }
      }
    };

    ws.onerror = (err) => {
      console.error("WebSocket error:", err);
    };

    return () => {
      ws.close();
    };
  }, [ws, esp32_unique_id]);

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
      {loading || !latestData ? (
        <Box display="flex" justifyContent="center" alignItems="center" height="100%">
          <CircularProgress />
        </Box>
      ) : (
        <Box>
          <Typography variant="body2" color="black">Tensão: {latestData.voltage.toFixed(2)} V</Typography>
          <Typography variant="body2" color="black">Corrente: {latestData.current.toFixed(2)} A</Typography>
          <Typography variant="body2" color="black">Temp. Painel Solar: {latestData.solar_panel_temperature.toFixed(2)} °C</Typography>
          <Typography variant="body2" color="black">Temp. Núcleo ESP32: {latestData.esp32_core_temperature.toFixed(2)} °C</Typography>
          <Typography variant="body2" color="black">Ângulo Torre Servo: {latestData.servo_tower_angle.toFixed(2)}°</Typography>
          <Typography variant="body2" color="black">Elevação Máxima: {latestData.max_elevation.toFixed(2)}°</Typography>
          <Typography variant="body2" color="black">Elevação Mínima: {latestData.min_elevation.toFixed(2)}°</Typography>
          <Typography variant="body2" color="black" sx={{ mt: 2 }}>Timestamp: {latestData.timestamp}</Typography>
        </Box>
      )}
    </Box>
  );
};

export default StatisticsCard;