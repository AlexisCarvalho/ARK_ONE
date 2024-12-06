#!/bin/bash

echo "=== Installing React packages and essential tools ==="
npm install react react-dom react-scripts typescript --save

echo "=== Installing routing packages ==="
npm install react-router-dom --save

echo "=== Installing Axios for HTTP requests ==="
npm install axios --save

echo "=== Installing Material-UI (MUI) ==="
npm install @mui/material @emotion/react @emotion/styled --save

echo "=== Installing React-Leaflet and Leaflet for maps ==="
npm install react-leaflet leaflet --save
npm install --save-dev @types/leaflet

echo "=== Installing Leaflet styles ==="
npm install leaflet/dist/leaflet.css --save

echo "=== Installing other required development dependencies ==="
npm install source-map-loader --save-dev

echo "=== Installing temporary QR code reader dependency ==="
npm install html5-qrcode

echo "=== Installation complete! ==="

