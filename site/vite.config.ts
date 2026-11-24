import { defineConfig } from "vite";

export default defineConfig({
  // Относительные пути: сайт работает и на <ник>.github.io/linux-learning/, и локально
  base: "./",
  server: {
    port: 5173,
    // Контент модулей лежит уровнем выше (общий с Docker-лабораторией)
    fs: { allow: [".."] },
  },
  // Браузерный тест в Docker заходит на сайт по имени host.docker.internal
  preview: { allowedHosts: ["host.docker.internal"] },
  build: {
    target: "es2022",
    chunkSizeWarningLimit: 2000,
  },
});
