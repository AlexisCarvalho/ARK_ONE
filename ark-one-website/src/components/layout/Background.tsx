import React from 'react';
import { useLocation } from 'react-router-dom';

import backgroundEvening from '../assets/background/background-evening.jpg';
import backgroundDay from '../assets/background/background-day.jpg';
import backgroundAfternoon from '../assets/background/background-afternoon.jpg';
import backgroundNight from '../assets/background/background-night.jpg';

const Background: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();

  const backgroundImages: { [key: string]: string } = {
    '/': backgroundEvening,
    '/login': backgroundEvening,
    '/register': backgroundEvening,
    '/productList': backgroundDay,
    '/purchasedProducts': backgroundDay,
    '/specificPurchasedProduct': backgroundAfternoon,
    '/registerESP32': backgroundAfternoon,
    '/setLocationMap': backgroundAfternoon,
    '/dashboard': backgroundNight,
  };

  const currentBackground = backgroundImages[location.pathname] || backgroundDay;

  return (
    <div
      style={{
        backgroundImage: `url(${currentBackground})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        backgroundRepeat: 'no-repeat',
        backgroundAttachment: 'fixed',
        filter: 'brightness(0.8) contrast(1.2)',
        minHeight: '100vh',
        position: 'relative',
      }}
    >
      {children}
    </div>
  );
};

export default Background;