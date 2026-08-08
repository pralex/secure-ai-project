import { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div style={{ padding: '2rem', fontFamily: 'system-ui' }}>
      <h1>🔒 Secure AI Project</h1>
      <p>Backend: <a href="http://localhost:8000" target="_blank">http://localhost:8000</a></p>
      <p>API Health: <a href="http://localhost:8000/health" target="_blank">/health</a></p>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count}
      </button>
    </div>
  )
}

export default App
