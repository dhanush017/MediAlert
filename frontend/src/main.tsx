import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

// Day 1 skeleton: routes (today's doses, medicines, caregiver view) come in Day 4.
function App() {
  return (
    <main style={{ fontSize: "18px", padding: "1.5rem" }}>
      <h1>MediAlert</h1>
      <p>Frontend skeleton. Today's doses arrive on Day 4.</p>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
