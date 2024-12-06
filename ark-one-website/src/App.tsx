import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './components/Home';
import Login from './components/Login';
import Register from './components/Register';
import ProductList from './components/ProductList';
import NavBar from './components/NavBar';
import PurchasedProducts from './components/PurchasedProducts';
import SpecificPurchasedProduct from './components/SpecificPurchasedProduct';
import RegisterESP32 from './components/RegisterESP32';
import SetLocationMap from './components/SetLocationMap';
import Dashboard from './components/Dashboard';
import RegisterProduct from './components/RegisterProduct';
import RegisterCategory from './components/RegisterCategory';
import planoPadrao from './assets/background/planoPadrao.png';
import './App.css';

const App: React.FC = () => {
  return (
    <Router>
      <NavBar />
      <div
        className="container"
        style={{
          backgroundImage: `url(${planoPadrao})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundRepeat: 'no-repeat',
          minHeight: '100vh',
          paddingTop: '94px',
        }}
      >
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/products" element={<ProductList />} />
          <Route path="/purchasedProducts" element={<PurchasedProducts />} />
          <Route path="/specificPurchasedProduct" element={<SpecificPurchasedProduct />} />
          <Route path="/registerESP32" element={<RegisterESP32 />} />
          <Route path="/setLocationMap" element={<SetLocationMap />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/registerProduct" element={<RegisterProduct />} />
          <Route path="/registerCategory" element={<RegisterCategory />} />
        </Routes>
      </div>
    </Router>
  );
};

export default App;