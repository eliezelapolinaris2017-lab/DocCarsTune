import React, { useEffect, useMemo, useState } from "react";

/**
 * Repair Car Pro (Body-Only)
 * Single-file React app: dimensiones de carrocería para hojalatería
 * - Seed JSON editable en Admin
 * - Import/Export .json
 * - Selector Año/Marca/Modelo
 * - Dimensiones generales + puntos datum (X/Y/Z mm)
 * - Holguras objetivo (gaps) y tolerancias
 * - Procedimientos genéricos de bancada y ajuste
 * - Conversión mm ⇄ in
 * - Impresión/Descarga
 *
 * Nota legal: datos semilla son valores típicos públicos y puntos datum originales (no OEM).
 */

// ========= Seed DB (puedes reemplazarlo por tu JSON propio) =========
const SEED_DB = {
  meta: {
    name: "Repair Car Pro — Body Dimensions",
    version: "1.0.0",
    units: "mm", // mm por defecto
  },
  vehicles: [
    { id: "2016-Toyota-Corolla", year: 2016, make: "Toyota", model: "Corolla", body: "Sedan", market: "USDM", notes: "E170" },
    { id: "2012-Honda-Civic", year: 2012, make: "Honda", model: "Civic", body: "Sedan", market: "USDM", notes: "FB" },
    { id: "2015-Nissan-Sentra", year: 2015, make: "Nissan", model: "Sentra", body: "Sedan", market: "USDM", notes: "B17" },
    { id: "2014-Toyota-Camry", year: 2014, make: "Toyota", model: "Camry", body: "Sedan", market: "USDM", notes: "XV50" },
    { id: "2013-Ford-Focus", year: 2013, make: "Ford", model: "Focus", body: "Hatch/Sedan", market: "USDM", notes: "C346" },
    { id: "2016-Subaru-Impreza", year: 2016, make: "Subaru", model: "Impreza", body: "Sedan/HB", market: "USDM", notes: "GP/GJ" },
  ],
  // Dimensiones generales públicas (aprox) y objetivos de carrocería para taller
  specs: {
    "2016-Toyota-Corolla": {
      overall: { length_mm: 4620, width_mm: 1775, height_mm: 1460, wheelbase_mm: 2700, f_track_mm: 1530, r_track_mm: 1535 },
      gaps: { hood_mm: { target: 3.5, tol: 1.0 }, door_front_mm: { target: 3.5, tol: 1.0 }, door_rear_mm: { target: 3.5, tol: 1.0 }, trunk_mm: { target: 3.5, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Punta bastidor izq. (subframe)", x_mm: 420, y_mm: 0, z_mm: 520 },
        { name: "A2", desc: "Punta bastidor der. (subframe)", x_mm: -420, y_mm: 0, z_mm: 520 },
        { name: "B1", desc: "Torre amortiguador izq.", x_mm: 360, y_mm: 680, z_mm: 920 },
        { name: "B2", desc: "Torre amortiguador der.", x_mm: -360, y_mm: 680, z_mm: 920 },
        { name: "C1", desc: "Punto bisagra puerta delantera izq. (superior)", x_mm: 720, y_mm: 980, z_mm: 940 },
        { name: "C2", desc: "Punto bisagra puerta delantera der. (superior)", x_mm: -720, y_mm: 980, z_mm: 940 },
        { name: "D1", desc: "Soporte crash-box izq.", x_mm: 390, y_mm: -180, z_mm: 560 },
        { name: "D2", desc: "Soporte crash-box der.", x_mm: -390, y_mm: -180, z_mm: 560 }
      ],
      procedures: [
        "Nivelar el vehículo en bancada: comprueba burbuja y puntos A1/A2 ±1 mm en Z.",
        "Bloquear subframe en posición nominal usando mordazas con protectores.",
        "Verificar diagonal A1→B2 y A2→B1: diferencia ≤ 3 mm.",
        "Ajustar holguras de capó a 3.5 ±1.0 mm con topes y bisagras, centrando pestillo.",
        "Puertas: cuadrar con bisagras (X/Y), luego striker (Z), objetivo 3.5 ±1.0 mm en todo el perímetro."
      ]
    },
    "2012-Honda-Civic": {
      overall: { length_mm: 4550, width_mm: 1750, height_mm: 1430, wheelbase_mm: 2670, f_track_mm: 1500, r_track_mm: 1505 },
      gaps: { hood_mm: { target: 3.0, tol: 1.0 }, door_front_mm: { target: 3.0, tol: 1.0 }, door_rear_mm: { target: 3.0, tol: 1.0 }, trunk_mm: { target: 3.0, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Torre izq.", x_mm: 350, y_mm: 670, z_mm: 910 },
        { name: "A2", desc: "Torre der.", x_mm: -350, y_mm: 670, z_mm: 910 },
        { name: "B1", desc: "Punto longitudinal izq.", x_mm: 480, y_mm: 100, z_mm: 540 },
        { name: "B2", desc: "Punto longitudinal der.", x_mm: -480, y_mm: 100, z_mm: 540 }
      ],
      procedures: [
        "Nivelar bancada. Referenciar Z en las torres A1/A2.",
        "Corregir torceduras midiendo diagonales A1→B2 vs A2→B1 ≤ 2 mm.",
        "Capó objetivo 3.0 ±1.0 mm; ajustar topes y bisagras."
      ]
    },
    "2015-Nissan-Sentra": {
      overall: { length_mm: 4615, width_mm: 1760, height_mm: 1500, wheelbase_mm: 2700, f_track_mm: 1520, r_track_mm: 1520 },
      gaps: { hood_mm: { target: 3.0, tol: 1.0 }, door_front_mm: { target: 3.5, tol: 1.0 }, door_rear_mm: { target: 3.5, tol: 1.0 }, trunk_mm: { target: 3.5, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Crash-box izq.", x_mm: 400, y_mm: -160, z_mm: 560 },
        { name: "A2", desc: "Crash-box der.", x_mm: -400, y_mm: -160, z_mm: 560 },
        { name: "B1", desc: "Torre izq.", x_mm: 355, y_mm: 700, z_mm: 930 },
        { name: "B2", desc: "Torre der.", x_mm: -355, y_mm: 700, z_mm: 930 }
      ],
      procedures: [
        "Fijar chasis en bancada con puntos A1/A2.",
        "Comprobar verticalidad torres ±1 mm en Z.",
        "Ajustar puertas a 3.5 ±1.0 mm; striker en último paso."
      ]
    },
    "2014-Toyota-Camry": {
      overall: { length_mm: 4825, width_mm: 1820, height_mm: 1470, wheelbase_mm: 2775, f_track_mm: 1570, r_track_mm: 1560 },
      gaps: { hood_mm: { target: 3.5, tol: 1.0 }, door_front_mm: { target: 3.5, tol: 1.0 }, door_rear_mm: { target: 3.5, tol: 1.0 }, trunk_mm: { target: 3.5, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Soporte longitudinal izq.", x_mm: 430, y_mm: -120, z_mm: 555 },
        { name: "A2", desc: "Soporte longitudinal der.", x_mm: -430, y_mm: -120, z_mm: 555 },
        { name: "B1", desc: "Torre izq.", x_mm: 370, y_mm: 710, z_mm: 935 },
        { name: "B2", desc: "Torre der.", x_mm: -370, y_mm: 710, z_mm: 935 }
      ],
      procedures: [
        "Nivel y fijación en bancada.",
        "Control de diagonales A1→B2 vs A2→B1 ≤ 3 mm.",
        "Ajuste de capó/maletero a 3.5 ±1.0 mm."
      ]
    },
    "2013-Ford-Focus": {
      overall: { length_mm: 4358, width_mm: 1823, height_mm: 1484, wheelbase_mm: 2648, f_track_mm: 1551, r_track_mm: 1548 },
      gaps: { hood_mm: { target: 3.0, tol: 1.0 }, door_front_mm: { target: 3.2, tol: 1.0 }, door_rear_mm: { target: 3.2, tol: 1.0 }, trunk_mm: { target: 3.2, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Punto longitudinal izq.", x_mm: 410, y_mm: -140, z_mm: 545 },
        { name: "A2", desc: "Punto longitudinal der.", x_mm: -410, y_mm: -140, z_mm: 545 },
        { name: "B1", desc: "Torre izq.", x_mm: 340, y_mm: 690, z_mm: 920 },
        { name: "B2", desc: "Torre der.", x_mm: -340, y_mm: 690, z_mm: 920 }
      ],
      procedures: [
        "Bloqueo del chasis y verificación de paralelismo de largueros.",
        "Holguras objetivo 3.2 ±1.0 mm; usar galgas.",
        "Registrar antes/después para control de calidad."
      ]
    },
    "2016-Subaru-Impreza": {
      overall: { length_mm: 4580, width_mm: 1740, height_mm: 1465, wheelbase_mm: 2645, f_track_mm: 1510, r_track_mm: 1515 },
      gaps: { hood_mm: { target: 3.0, tol: 1.0 }, door_front_mm: { target: 3.0, tol: 1.0 }, door_rear_mm: { target: 3.0, tol: 1.0 }, trunk_mm: { target: 3.0, tol: 1.0 } },
      datum: [
        { name: "A1", desc: "Punto traviesa frontal izq.", x_mm: 395, y_mm: -150, z_mm: 555 },
        { name: "A2", desc: "Punto traviesa frontal der.", x_mm: -395, y_mm: -150, z_mm: 555 },
        { name: "B1", desc: "Torre izq.", x_mm: 330, y_mm: 685, z_mm: 915 },
        { name: "B2", desc: "Torre der.", x_mm: -330, y_mm: 685, z_mm: 915 }
      ],
      procedures: [
        "Nivelar bancada; 0 ±1 mm de diferencia en A1/A2 en Z.",
        "Subframe: pinza y centrado a especificación nominal.",
        "Gaps objetivo 3.0 ±1.0 mm."
      ]
    }
  },
  dtc: [], // no aplica al módulo de carrocería, lo dejamos vacío para mantener formato conocido
};

// ========= Helpers =========
const DB_KEY = "repaircarpro.body.db";
const deepClone = (o) => JSON.parse(JSON.stringify(o));
const mmToIn = (mm) => mm / 25.4;
const inToMm = (inch) => inch * 25.4;

function useLocalDB() {
  const [db, setDb] = useState(() => {
    const raw = localStorage.getItem(DB_KEY);
    if (!raw) {
      localStorage.setItem(DB_KEY, JSON.stringify(SEED_DB));
      return deepClone(SEED_DB);
    }
    try { return JSON.parse(raw); } catch { return deepClone(SEED_DB); }
  });
  const save = (next) => {
    setDb(next);
    localStorage.setItem(DB_KEY, JSON.stringify(next));
  };
  return [db, save];
}

function groupBy(arr, key) {
  return arr.reduce((acc, it) => {
    const k = it[key];
    if (!acc[k]) acc[k] = [];
    acc[k].push(it);
    return acc;
  }, {});
}

// ========= UI =========
export default function App() {
  const [db, saveDb] = useLocalDB();
  const [tab, setTab] = useState("finder");
  const [unit, setUnit] = useState("mm");
  const [selectedVID, setSelectedVID] = useState("");
  const [filter, setFilter] = useState({ year: "", make: "", model: "" });

  const vidList = db.vehicles;
  const years = useMemo(() => Array.from(new Set(vidList.map(v => v.year))).sort((a,b)=>b-a), [vidList]);
  const makes = useMemo(() => Array.from(new Set(vidList.filter(v => !filter.year || v.year === Number(filter.year)).map(v => v.make))).sort(), [vidList, filter.year]);
  const models = useMemo(() => Array.from(new Set(vidList.filter(v => (!filter.year || v.year === Number(filter.year)) && (!filter.make || v.make === filter.make)).map(v => v.model))).sort(), [vidList, filter.year, filter.make]);

  const selected = useMemo(() => vidList.find(v => v.id === selectedVID) || null, [vidList, selectedVID]);
  const spec = selected ? db.specs[selected.id] : null;

  function onExport() {
    const blob = new Blob([JSON.stringify(db, null, 2)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "repair_car_pro_body_db.json";
    a.click();
  }

  function onImport(e) {
    const f = e.target.files?.[0];
    if (!f) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result);
        if (!data.vehicles || !data.specs) throw new Error("Estructura inválida: faltan vehicles/specs");
        saveDb(data);
        alert("Base importada correctamente.");
      } catch (err) { alert("Error al importar: " + err.message); }
    };
    reader.readAsText(f);
  }

  function addVehicle(v) {
    const next = deepClone(db);
    if (next.vehicles.some(x => x.id === v.id)) return alert("Ya existe ese ID");
    next.vehicles.push(v);
    next.specs[v.id] = {
      overall: { length_mm: 0, width_mm: 0, height_mm: 0, wheelbase_mm: 0, f_track_mm: 0, r_track_mm: 0 },
      gaps: { hood_mm: { target: 3.0, tol: 1.0 }, door_front_mm: { target: 3.0, tol: 1.0 }, door_rear_mm: { target: 3.0, tol: 1.0 }, trunk_mm: { target: 3.0, tol: 1.0 } },
      datum: [],
      procedures: [],
    };
    saveDb(next);
  }

  function addDatum(p) {
    if (!selected) return;
    const next = deepClone(db);
    next.specs[selected.id].datum.push(p);
    saveDb(next);
  }

  function addProcedure(text) {
    if (!selected) return;
    const next = deepClone(db);
    next.specs[selected.id].procedures.push(text);
    saveDb(next);
  }

  function updateOverall(field, val) {
    if (!selected) return;
    const next = deepClone(db);
    next.specs[selected.id].overall[field] = Number(val) || 0;
    saveDb(next);
  }

  function updateGap(field, key, val) {
    if (!selected) return;
    const next = deepClone(db);
    next.specs[selected.id].gaps[field][key] = Number(val) || 0;
    saveDb(next);
  }

  function printSheet() {
    window.print();
  }

  const filtered = vidList.filter(v => (
    (!filter.year || v.year === Number(filter.year)) &&
    (!filter.make || v.make === filter.make) &&
    (!filter.model || v.model === filter.model)
  ));

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 p-4">
      <header className="flex items-center justify-between gap-2 mb-4">
        <div>
          <h1 className="text-2xl font-bold">Repair Car Pro — Carrocería</h1>
          <p className="text-neutral-400 text-sm">Dimensiones y holguras para hojalatería | Base local (JSON)</p>
        </div>
        <div className="flex items-center gap-2">
          <select className="bg-neutral-800 rounded px-2 py-1" value={unit} onChange={(e)=>setUnit(e.target.value)}>
            <option value="mm">mm</option>
            <option value="in">in</option>
          </select>
          <button className="rounded-2xl px-3 py-1 bg-neutral-800 hover:bg-neutral-700" onClick={onExport}>Exportar JSON</button>
          <label className="rounded-2xl px-3 py-1 bg-neutral-800 hover:bg-neutral-700 cursor-pointer">
            Importar JSON
            <input type="file" accept="application/json" className="hidden" onChange={onImport}/>
          </label>
          <button className="rounded-2xl px-3 py-1 bg-neutral-800 hover:bg-neutral-700" onClick={printSheet}>Imprimir</button>
        </div>
      </header>

      <nav className="flex gap-2 mb-4">
        {['finder','viewer','admin','help'].map(t=> (
          <button key={t} onClick={()=>setTab(t)} className={`px-3 py-1 rounded-2xl ${tab===t? 'bg-emerald-600' : 'bg-neutral-800 hover:bg-neutral-700'}`}>{t}</button>
        ))}
      </nav>

      {tab === 'finder' && (
        <section className="grid md:grid-cols-3 gap-4">
          <div className="bg-neutral-900 rounded-2xl p-4 space-y-2">
            <h2 className="text-lg font-semibold">Buscar vehículo</h2>
            <div className="grid grid-cols-3 gap-2">
              <select className="bg-neutral-800 rounded px-2 py-1" value={filter.year} onChange={e=>setFilter(f=>({...f, year: e.target.value}))}>
                <option value="">Año</option>
                {years.map(y => <option key={y} value={y}>{y}</option>)}
              </select>
              <select className="bg-neutral-800 rounded px-2 py-1" value={filter.make} onChange={e=>setFilter(f=>({...f, make: e.target.value}))}>
                <option value="">Marca</option>
                {makes.map(m => <option key={m} value={m}>{m}</option>)}
              </select>
              <select className="bg-neutral-800 rounded px-2 py-1" value={filter.model} onChange={e=>setFilter(f=>({...f, model: e.target.value}))}>
                <option value="">Modelo</option>
                {models.map(m => <option key={m} value={m}>{m}</option>)}
              </select>
            </div>
            <div className="max-h-80 overflow-auto border border-neutral-800 rounded-xl">
              {filtered.map(v => (
                <button key={v.id} onClick={()=>{setSelectedVID(v.id); setTab('viewer')}} className={`w-full text-left p-3 hover:bg-neutral-800 ${selectedVID===v.id?'bg-neutral-800':''}`}>
                  <div className="font-medium">{v.year} {v.make} {v.model}</div>
                  <div className="text-neutral-400 text-sm">{v.body} • {v.market} • {v.notes}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="md:col-span-2 bg-neutral-900 rounded-2xl p-4">
            <h2 className="text-lg font-semibold mb-2">Resumen</h2>
            <p className="text-neutral-400">Selecciona un vehículo para ver dimensiones, puntos datum y holguras recomendadas. Cambia unidades en el encabezado.</p>
          </div>
        </section>
      )}

      {tab === 'viewer' && (
        <section className="grid lg:grid-cols-2 gap-4">
          <div className="bg-neutral-900 rounded-2xl p-4">
            {selected ? (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <h2 className="text-lg font-semibold">{selected.year} {selected.make} {selected.model}</h2>
                  <span className="text-neutral-400 text-sm">{selected.body} • {selected.market}</span>
                </div>
                {spec ? (
                  <div className="grid md:grid-cols-2 gap-3">
                    <div className="bg-neutral-800 rounded-xl p-3">
                      <h3 className="font-semibold mb-2">Dimensiones generales ({unit})</h3>
                      {Object.entries(spec.overall).map(([k,val])=>{
                        const display = unit==='mm' ? val : (val? mmToIn(val):0);
                        const label = k.replace(/_/g,' ');
                        return (
                          <div key={k} className="flex items-center justify-between text-sm py-1 border-b border-neutral-700/50">
                            <span className="capitalize">{label}</span>
                            <span>{display? display.toFixed(1):0}</span>
                          </div>
                        );
                      })}
                    </div>
                    <div className="bg-neutral-800 rounded-xl p-3">
                      <h3 className="font-semibold mb-2">Holguras objetivo</h3>
                      {Object.entries(spec.gaps).map(([name,obj])=> (
                        <div key={name} className="flex items-center justify-between text-sm py-1 border-b border-neutral-700/50">
                          <span className="capitalize">{name.replace(/_/g,' ')}</span>
                          <span>{unit==='mm' ? `${obj.target} ±${obj.tol}` : `${mmToIn(obj.target).toFixed(2)} ±${mmToIn(obj.tol).toFixed(2)}`}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ) : <p className="text-neutral-400">Sin specs.</p>}
              </div>
            ) : <p className="text-neutral-400">Selecciona un vehículo en Finder.</p>}
          </div>

          <div className="bg-neutral-900 rounded-2xl p-4">
            <h3 className="font-semibold mb-2">Puntos datum (X/Y/Z {unit})</h3>
            {spec && spec.datum?.length ? (
              <div className="max-h-80 overflow-auto border border-neutral-800 rounded-xl">
                <table className="w-full text-sm">
                  <thead className="bg-neutral-800 sticky top-0">
                    <tr>
                      <th className="text-left p-2">Punto</th>
                      <th className="text-left p-2">Descripción</th>
                      <th className="text-right p-2">X</th>
                      <th className="text-right p-2">Y</th>
                      <th className="text-right p-2">Z</th>
                    </tr>
                  </thead>
                  <tbody>
                    {spec.datum.map((p,idx)=>{
                      const toUnit = (v)=> unit==='mm'? v : mmToIn(v);
                      return (
                        <tr key={idx} className="odd:bg-neutral-900 even:bg-neutral-900/60">
                          <td className="p-2 font-medium">{p.name}</td>
                          <td className="p-2 text-neutral-300">{p.desc}</td>
                          <td className="p-2 text-right">{toUnit(p.x_mm).toFixed(1)}</td>
                          <td className="p-2 text-right">{toUnit(p.y_mm).toFixed(1)}</td>
                          <td className="p-2 text-right">{toUnit(p.z_mm).toFixed(1)}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : <p className="text-neutral-400">Añade puntos datum en Admin.</p>}

            <div className="mt-4">
              <h3 className="font-semibold mb-2">Procedimientos</h3>
              {spec?.procedures?.length ? (
                <ol className="list-decimal list-inside space-y-1 text-sm text-neutral-200">
                  {spec.procedures.map((s,i)=>(<li key={i}>{s}</li>))}
                </ol>
              ) : <p className="text-neutral-400">Sin procedimientos. Agrega en Admin.</p>}
            </div>
          </div>
        </section>
      )}

      {tab === 'admin' && (
        <section className="grid lg:grid-cols-2 gap-4">
          <div className="bg-neutral-900 rounded-2xl p-4 space-y-3">
            <h2 className="text-lg font-semibold">Añadir vehículo</h2>
            <VehicleForm onSubmit={addVehicle} />
            <div className="text-neutral-400 text-xs">Al crear, se generan specs vacías con holguras por defecto.</div>
          </div>

          <div className="bg-neutral-900 rounded-2xl p-4 space-y-3">
            <h2 className="text-lg font-semibold">Editar vehículo seleccionado</h2>
            {selected ? (
              <div className="space-y-4">
                <h3 className="font-medium">{selected.year} {selected.make} {selected.model}</h3>
                <div className="grid md:grid-cols-2 gap-3">
                  <Card title="Dimensiones generales (mm)">
                    {spec && (
                      <div className="grid grid-cols-2 gap-2 text-sm">
                        {Object.entries(spec.overall).map(([k, val]) => (
                          <label key={k} className="flex flex-col gap-1">
                            <span className="text-neutral-300 capitalize">{k.replace(/_/g,' ')}</span>
                            <input className="bg-neutral-800 rounded px-2 py-1" type="number" step="0.1" value={val} onChange={(e)=>updateOverall(k, e.target.value)} />
                          </label>
                        ))}
                      </div>
                    )}
                  </Card>
                  <Card title="Holguras objetivo (mm)">
                    {spec && (
                      <div className="grid grid-cols-2 gap-2 text-sm">
                        {Object.entries(spec.gaps).map(([name,obj])=> (
                          <div key={name} className="border border-neutral-800 rounded p-2">
                            <div className="font-medium mb-1">{name.replace(/_/g,' ')}</div>
                            <label className="flex items-center gap-2 text-xs">
                              <span>target</span>
                              <input className="bg-neutral-800 rounded px-2 py-1 w-20" type="number" step="0.1" value={obj.target} onChange={(e)=>updateGap(name,'target', e.target.value)} />
                            </label>
                            <label className="flex items-center gap-2 text-xs mt-1">
                              <span>± tol</span>
                              <input className="bg-neutral-800 rounded px-2 py-1 w-20" type="number" step="0.1" value={obj.tol} onChange={(e)=>updateGap(name,'tol', e.target.value)} />
                            </label>
                          </div>
                        ))}
                      </div>
                    )}
                  </Card>
                </div>

                <Card title="Añadir punto datum (mm)">
                  <DatumForm onSubmit={addDatum} />
                </Card>

                <Card title="Añadir procedimiento">
                  <ProcedureForm onSubmit={addProcedure} />
                </Card>
              </div>
            ) : <p className="text-neutral-400">Selecciona un vehículo en Finder y vuelve aquí.</p>}
          </div>
        </section>
      )}

      {tab === 'help' && (
        <section className="bg-neutral-900 rounded-2xl p-4 space-y-3">
          <h2 className="text-lg font-semibold">Ayuda rápida</h2>
          <ul className="list-disc list-inside text-sm text-neutral-300 space-y-1">
            <li>Las dimensiones generales son públicas y orientativas; para litigios/seguros usa medición 3D certificada.</li>
            <li>Los puntos datum son originales de este paquete (no OEM) y sirven para control de bancada (ejes X/Y/Z).</li>
            <li>Puedes importar tu propio JSON (mismo formato) o exportar el actual.</li>
            <li>Usa <b>Imprimir</b> para generar una hoja de orden de reparación con las medidas objetivo.</li>
          </ul>
          <p className="text-neutral-500 text-xs">© Repair Car Pro (Body-Only). Hecho para talleres de hojalatería.</p>
        </section>
      )}
    </div>
  );
}

function Card({ title, children }) {
  return (
    <div className="bg-neutral-800 rounded-xl p-3">
      <div className="font-semibold mb-2">{title}</div>
      {children}
    </div>
  );
}

function VehicleForm({ onSubmit }) {
  const [y, setY] = useState(2020);
  const [make, setMake] = useState("");
  const [model, setModel] = useState("");
  const [body, setBody] = useState("Sedan");
  const [market, setMarket] = useState("USDM");
  const [notes, setNotes] = useState("");

  function submit() {
    if (!y || !make || !model) return alert("Año, Marca y Modelo son obligatorios");
    const id = `${y}-${make}-${model}`.replace(/\s+/g,'-');
    onSubmit({ id, year: Number(y), make: make.trim(), model: model.trim(), body, market, notes });
  }
  return (
    <div className="grid md:grid-cols-3 gap-2 text-sm">
      <label className="flex flex-col gap-1"><span>Año</span><input className="bg-neutral-800 rounded px-2 py-1" type="number" value={y} onChange={e=>setY(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>Marca</span><input className="bg-neutral-800 rounded px-2 py-1" value={make} onChange={e=>setMake(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>Modelo</span><input className="bg-neutral-800 rounded px-2 py-1" value={model} onChange={e=>setModel(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>Carrocería</span><input className="bg-neutral-800 rounded px-2 py-1" value={body} onChange={e=>setBody(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>Mercado</span><input className="bg-neutral-800 rounded px-2 py-1" value={market} onChange={e=>setMarket(e.target.value)} /></label>
      <label className="md:col-span-3 flex flex-col gap-1"><span>Notas</span><input className="bg-neutral-800 rounded px-2 py-1" value={notes} onChange={e=>setNotes(e.target.value)} /></label>
      <div className="md:col-span-3 flex justify-end"><button className="rounded-2xl px-3 py-1 bg-emerald-600 hover:bg-emerald-500" onClick={submit}>Añadir</button></div>
    </div>
  );
}

function DatumForm({ onSubmit }) {
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [x, setX] = useState(0);
  const [y, setY] = useState(0);
  const [z, setZ] = useState(0);
  function submit() {
    if (!name) return alert("Nombre de punto requerido");
    onSubmit({ name: name.trim(), desc: desc.trim(), x_mm: Number(x), y_mm: Number(y), z_mm: Number(z) });
    setName(""); setDesc(""); setX(0); setY(0); setZ(0);
  }
  return (
    <div className="grid md:grid-cols-5 gap-2 text-sm">
      <label className="flex flex-col gap-1 md:col-span-1"><span>Punto</span><input className="bg-neutral-800 rounded px-2 py-1" value={name} onChange={e=>setName(e.target.value)} /></label>
      <label className="flex flex-col gap-1 md:col-span-2"><span>Descripción</span><input className="bg-neutral-800 rounded px-2 py-1" value={desc} onChange={e=>setDesc(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>X (mm)</span><input className="bg-neutral-800 rounded px-2 py-1" type="number" step="0.1" value={x} onChange={e=>setX(e.target.value)} /></label>
      <label className="flex flex-col gap-1"><span>Y (mm)</span><input className="bg-neutral-800 rounded px-2 py-1" type="number" step="0.1" value={y} onChange={e=>setY(e.target.value)} /></label>
      <label className="flex flex-col gap-1 md:col-span-1"><span>Z (mm)</span><input className="bg-neutral-800 rounded px-2 py-1" type="number" step="0.1" value={z} onChange={e=>setZ(e.target.value)} /></label>
      <div className="md:col-span-5 flex justify-end"><button className="rounded-2xl px-3 py-1 bg-emerald-600 hover:bg-emerald-500" onClick={submit}>Añadir punto</button></div>
    </div>
  );
}

function ProcedureForm({ onSubmit }) {
  const [t, setT] = useState("");
  function submit(){ if(!t.trim()) return; onSubmit(t.trim()); setT(""); }
  return (
    <div className="flex gap-2">
      <input className="flex-1 bg-neutral-800 rounded px-2 py-1" placeholder="Paso/procedimiento" value={t} onChange={e=>setT(e.target.value)} />
      <button className="rounded-2xl px-3 py-1 bg-emerald-600 hover:bg-emerald-500" onClick={submit}>Añadir</button>
    </div>
  );
}
