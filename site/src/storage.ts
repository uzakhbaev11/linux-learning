// Хранилище в браузере.
// IndexedDB — для большого снимка Linux, localStorage — для мелких настроек.

const DB_NAME = "linux-lab";
const STORE = "state";

function withStore<T>(mode: IDBTransactionMode, fn: (s: IDBObjectStore) => IDBRequest<T> | void): Promise<T | undefined> {
  return new Promise((resolve, reject) => {
    const open = indexedDB.open(DB_NAME, 1);
    open.onupgradeneeded = () => open.result.createObjectStore(STORE);
    open.onerror = () => reject(open.error);
    open.onsuccess = () => {
      const tx = open.result.transaction(STORE, mode);
      const req = fn(tx.objectStore(STORE));
      tx.oncomplete = () => resolve(req ? req.result : undefined);
      tx.onerror = () => reject(tx.error);
    };
  });
}

// Сохранение Linux: сжатый снимок + версия образа, для которого он сделан
export type VmRecord = { version: string; data: ArrayBuffer };

export const vmStore = {
  load: async (): Promise<VmRecord | undefined> => {
    const r = await withStore<unknown>("readonly", (s) => s.get("vm")).catch(() => undefined);
    // Записи старого формата (просто ArrayBuffer из прототипа) игнорируем
    return r && typeof r === "object" && "version" in r ? (r as VmRecord) : undefined;
  },
  save: (rec: VmRecord) => withStore("readwrite", (s) => { s.put(rec, "vm"); }),
  clear: () => withStore("readwrite", (s) => { s.delete("vm"); }),
};

// Прогресс по модулям
export type ModuleProgress = { tasks?: boolean; quiz?: boolean };
export const progress = {
  all(): Record<string, ModuleProgress> {
    try { return JSON.parse(prefs.get("progress") || "{}"); } catch { return {}; }
  },
  get(num: string): ModuleProgress { return this.all()[num] || {}; },
  set(num: string, p: ModuleProgress) {
    const all = this.all();
    all[num] = { ...all[num], ...p };
    prefs.set("progress", JSON.stringify(all));
  },
  done(num: string) { const p = this.get(num); return Boolean(p.tasks && p.quiz); },
};

// localStorage может быть недоступен (приватный режим и т.п.) — тогда просто работаем без него
export const prefs = {
  get(key: string): string | null {
    try { return localStorage.getItem("linux-lab:" + key); } catch { return null; }
  },
  set(key: string, value: string) {
    try { localStorage.setItem("linux-lab:" + key, value); } catch { /* ничего */ }
  },
};
