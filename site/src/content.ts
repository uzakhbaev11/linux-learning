// Модули курса. Тексты берутся из общей папки linux-learning/modules —
// те же файлы, что и в Docker-лаборатории.

const files = import.meta.glob("../../modules/*/*.md", {
  query: "?raw",
  import: "default",
  eager: true,
}) as Record<string, string>;

export type Module = {
  num: string;              // "01"
  title: string;            // "Терминал"
  part: string;             // "Основы"
  theory?: string;          // markdown
  tasks?: string;           // markdown
};

// Полная программа курса (из README). Модули без файлов показываются как «скоро».
const PROGRAM: Array<[string, string, string]> = [
  ["01", "Терминал", "Основы"],
  ["02", "Файловая система", "Основы"],
  ["03", "Текст и редакторы", "Основы"],
  ["04", "Пайпы и перенаправления", "Основы"],
  ["05", "Пользователи и права", "Система"],
  ["06", "Процессы и сигналы", "Система"],
  ["07", "Пакеты и окружение", "Система"],
  ["08", "Bash-скрипты", "Автоматизация"],
  ["09", "Cron, архивы, бэкапы", "Автоматизация"],
  ["10", "Сеть", "Сервер"],
  ["11", "SSH", "Сервер"],
  ["12", "systemd и логи", "Сервер"],
];

export const modules: Module[] = PROGRAM.map(([num, title, part]) => {
  const find = (name: string) =>
    Object.entries(files).find(([path]) => path.includes(`/modules/${num}-`) && path.endsWith(`/${name}.md`))?.[1];
  return { num, title, part, theory: find("theory"), tasks: find("tasks") };
});

export const available = (m: Module) => Boolean(m.theory);
