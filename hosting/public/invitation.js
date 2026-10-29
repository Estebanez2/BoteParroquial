"use strict";
// No SDK, tracking, fetch, third-party resources or HTML interpolation of the code.
const match = /^\/join\/([A-Za-z0-9_-]{1,128}\.[A-Za-z0-9_-]{32})$/.exec(location.pathname);
if (match) {
  const code = match[1];
  document.getElementById("invitation").hidden = false;
  const open = document.getElementById("open");
  if (/Android/i.test(navigator.userAgent)) {
    open.hidden = false;
    open.href = `intent://boteparroquial.web.app/join/${code}#Intent;scheme=https;package=com.example.bote_parroquial;end`;
  }
  document.getElementById("copy").addEventListener("click", async () => {
    const feedback = document.getElementById("feedback");
    try {
      await navigator.clipboard.writeText(code);
      feedback.textContent = "Código copiado. Pégalo en «Entrar en un grupo» dentro de la app.";
    } catch { feedback.textContent = `Copia este código en la app: ${code}`; }
  });
} else {
  document.getElementById("message").textContent = "Este enlace no contiene una invitación válida. Pide un enlace completo a alguien del grupo.";
}
