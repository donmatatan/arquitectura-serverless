// La URL de la API la inyecta 04-s3.sh (reemplaza __API_URL__ al momento del deploy)
const API_URL = "__API_URL__";

document.getElementById("api-url").textContent = API_URL;

function formatearFecha(iso) {
  try { return new Date(iso).toLocaleString("es-CL"); } catch { return iso; }
}

async function cargarUsuarios() {
  const ul = document.getElementById("lista-usuarios");
  try {
    const res = await fetch(`${API_URL}/usuarios`);
    const datos = await res.json();
    ul.innerHTML = datos.usuarios
      .map(u => `<li>${u.nombre} — ${u.email}</li>`)
      .join("");
  } catch (err) {
    ul.innerHTML = `<li>Error cargando usuarios: ${err.message}</li>`;
  }
}

async function cargarPedidos() {
  const tbody = document.querySelector("#tabla-pedidos tbody");
  tbody.innerHTML = `<tr><td colspan="6">Cargando...</td></tr>`;
  try {
    const res = await fetch(`${API_URL}/pedidos`);
    const datos = await res.json();
    if (!datos.pedidos || datos.pedidos.length === 0) {
      tbody.innerHTML = `<tr><td colspan="6">Aún no hay pedidos</td></tr>`;
      return;
    }
    tbody.innerHTML = datos.pedidos
      .map(p => `<tr>
        <td>${p.orderId}</td><td>${p.producto}</td><td>${p.cantidad}</td>
        <td>${p.cliente}</td><td>${p.estado}</td><td>${formatearFecha(p.creadoEn)}</td>
      </tr>`)
      .join("");
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="6">Error cargando pedidos: ${err.message}</td></tr>`;
  }
}

function mostrarMensaje(texto, tipo) {
  const el = document.getElementById("mensaje");
  el.textContent = texto;
  el.className = `mensaje ${tipo}`;
  el.hidden = false;
}

document.getElementById("form-pedido").addEventListener("submit", async (e) => {
  e.preventDefault();
  const cuerpo = {
    producto: document.getElementById("producto").value.trim(),
    cantidad: Number(document.getElementById("cantidad").value),
    cliente: document.getElementById("cliente").value.trim(),
  };
  try {
    const res = await fetch(`${API_URL}/pedidos`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(cuerpo),
    });
    const datos = await res.json();
    if (!res.ok) throw new Error(datos.error || "Error desconocido");
    mostrarMensaje(`✓ Pedido ${datos.orderId} creado`, "ok");
    e.target.reset();
    document.getElementById("cantidad").value = 1;
    cargarPedidos();
  } catch (err) {
    mostrarMensaje(`✗ ${err.message}`, "error");
  }
});

document.getElementById("btn-actualizar").addEventListener("click", cargarPedidos);

cargarUsuarios();
cargarPedidos();
