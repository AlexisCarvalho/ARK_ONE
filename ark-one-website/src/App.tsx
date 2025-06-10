import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Home from './components/pages/Home';
import Login from './components/pages/Login';
import Register from './components/pages/Register';
import ProductList from './components/pages/ProductList';
import NavBar from './components/layout/NavBar';
import PurchasedProducts from './components/pages/PurchasedProducts';
import SpecificPurchasedProduct from './components/pages/SpecificPurchasedProduct';
import RegisterESP32 from './components/pages/RegisterESP32';
import SetLocationMap from './components/pages/SetLocationMap';
import Dashboard from './components/pages/Dashboard';
import RegisterProduct from './components/pages/RegisterProduct';
import RegisterCategory from './components/pages/RegisterCategory';
import './App.css';

const AppContent: React.FC = () => {
  const location = useLocation();

  return (
    <div className="app-wrapper">
      <NavBar />
      <div className="container">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/productList" element={<ProductList />} />
          <Route path="/purchasedProducts" element={<PurchasedProducts />} />
          <Route path="/specificPurchasedProduct" element={<SpecificPurchasedProduct />} />
          <Route path="/registerESP32" element={<RegisterESP32 />} />
          <Route path="/setLocationMap" element={<SetLocationMap />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/registerProduct" element={<RegisterProduct />} />
          <Route path="/registerCategory" element={<RegisterCategory />} />
        </Routes>
      </div>
    </div>
  );
};

const App: React.FC = () => {
  return (
    <Router>
      <AppContent />
    </Router>
  );
};

export default App;