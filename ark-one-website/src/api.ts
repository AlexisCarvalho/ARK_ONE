import axios from 'axios';
import { authToken } from './auth';

const api = axios.create({
  baseURL: 'http://192.168.0.139:8000/',
});

api.interceptors.request.use(config => {
  if (authToken) {
    config.headers.Authorization = `Bearer ${authToken}`;
  }
  return config;
});

export default api;
