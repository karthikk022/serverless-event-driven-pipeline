import { useEffect, useRef, useState } from 'react'
import { Badge } from '@/components/ui/badge'

interface ServiceNode {
  id: string
  name: string
  icon: string
  x: number
  y: number
  color: string
  category: string
}

interface Connection {
  from: string
  to: string
  color: string
  label: string
}

const services: ServiceNode[] = [
  { id: 's3', name: 'S3', icon: '📦', x: 100, y: 80, color: '#f97316', category: 'Storage' },
  { id: 'api', name: 'API Gateway', icon: '🌐', x: 100, y: 200, color: '#8b5cf6', category: 'API' },
  { id: 'lambda1', name: 'S3 Processor', icon: 'λ', x: 300, y: 80, color: '#3b82f6', category: 'Compute' },
  { id: 'lambda2', name: 'API Handler', icon: 'λ', x: 300, y: 200, color: '#3b82f6', category: 'Compute' },
  { id: 'ddb', name: 'DynamoDB', icon: '🗄️', x: 500, y: 80, color: '#06b6d4', category: 'Database' },
  { id: 'streams', name: 'DynamoDB Streams', icon: '📊', x: 500, y: 200, color: '#06b6d4', category: 'Database' },
  { id: 'lambda3', name: 'Stream Processor', icon: 'λ', x: 700, y: 80, color: '#3b82f6', category: 'Compute' },
  { id: 'eb', name: 'EventBridge', icon: '📡', x: 500, y: 320, color: '#a855f7', category: 'Event Bus' },
  { id: 'lambda4', name: 'Event Processor', icon: 'λ', x: 700, y: 320, color: '#3b82f6', category: 'Compute' },
  { id: 'sfn', name: 'Step Functions', icon: '⚙️', x: 900, y: 320, color: '#ef4444', category: 'Orchestration' },
  { id: 'lambda5', name: 'Activities', icon: 'λ', x: 1100, y: 200, color: '#3b82f6', category: 'Compute' },
  { id: 'sns', name: 'SNS', icon: '📢', x: 700, y: 440, color: '#ec4899', category: 'Notification' },
  { id: 'xray', name: 'X-Ray', icon: '🔍', x: 900, y: 440, color: '#14b8a6', category: 'Tracing' },
  { id: 'cw', name: 'CloudWatch', icon: '📈', x: 1100, y: 440, color: '#f59e0b', category: 'Monitoring' },
]

const connections: Connection[] = [
  { from: 's3', to: 'lambda1', color: '#f97316', label: 'S3 Event' },
  { from: 'api', to: 'lambda2', color: '#8b5cf6', label: 'HTTP' },
  { from: 'lambda1', to: 'ddb', color: '#3b82f6', label: 'Write' },
  { from: 'lambda2', to: 'ddb', color: '#3b82f6', label: 'CRUD' },
  { from: 'ddb', to: 'streams', color: '#06b6d4', label: 'Stream' },
  { from: 'streams', to: 'lambda3', color: '#06b6d4', label: 'Records' },
  { from: 'lambda1', to: 'eb', color: '#f97316', label: 'Event' },
  { from: 'lambda3', to: 'eb', color: '#06b6d4', label: 'Event' },
  { from: 'lambda2', to: 'eb', color: '#8b5cf6', label: 'Event' },
  { from: 'eb', to: 'lambda4', color: '#a855f7', label: 'Route' },
  { from: 'eb', to: 'sfn', color: '#a855f7', label: 'Trigger' },
  { from: 'eb', to: 'sns', color: '#a855f7', label: 'Notify' },
  { from: 'lambda4', to: 'sfn', color: '#3b82f6', label: 'Start' },
  { from: 'sfn', to: 'lambda5', color: '#ef4444', label: 'Invoke' },
  { from: 'sfn', to: 'xray', color: '#ef4444', label: 'Trace' },
  { from: 'lambda5', to: 'cw', color: '#3b82f6', label: 'Metrics' },
  { from: 'sns', to: 'cw', color: '#ec4899', label: 'Alert' },
]

export default function ArchitectureDiagram() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [activeService, setActiveService] = useState<string | null>(null)
  const [animatedDots, setAnimatedDots] = useState(0)

  useEffect(() => {
    const interval = setInterval(() => {
      setAnimatedDots(prev => (prev + 1) % 100)
    }, 50)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width * dpr
    canvas.height = rect.height * dpr
    ctx.scale(dpr, dpr)

    const width = rect.width
    const height = rect.height

    ctx.clearRect(0, 0, width, height)

    // Draw connections
    connections.forEach((conn, idx) => {
      const fromService = services.find(s => s.id === conn.from)
      const toService = services.find(s => s.id === conn.to)
      if (!fromService || !toService) return

      const fx = (fromService.x / 1200) * width
      const fy = (fromService.y / 500) * height
      const tx = (toService.x / 1200) * width
      const ty = (toService.y / 500) * height

      // Draw line
      ctx.beginPath()
      ctx.moveTo(fx, fy)
      ctx.lineTo(tx, ty)
      ctx.strokeStyle = conn.color + '40'
      ctx.lineWidth = 2
      ctx.stroke()

      // Draw animated dot
      const progress = ((animatedDots + idx * 20) % 100) / 100
      const dx = tx - fx
      const dy = ty - fy
      const dotX = fx + dx * progress
      const dotY = fy + dy * progress

      ctx.beginPath()
      ctx.arc(dotX, dotY, 4, 0, Math.PI * 2)
      ctx.fillStyle = conn.color
      ctx.fill()
      ctx.shadowColor = conn.color
      ctx.shadowBlur = 8
      ctx.fill()
      ctx.shadowBlur = 0

      // Label (only on hover or for key paths)
      if (activeService === conn.from || activeService === conn.to || activeService === null) {
        const mx = (fx + tx) / 2
        const my = (fy + ty) / 2
        ctx.font = '10px sans-serif'
        ctx.fillStyle = conn.color + '80'
        ctx.textAlign = 'center'
        ctx.fillText(conn.label, mx, my - 6)
      }
    })

    // Draw service nodes
    services.forEach(service => {
      const x = (service.x / 1200) * width
      const y = (service.y / 500) * height
      const isActive = activeService === service.id
      const isConnected = activeService && connections.some(c => 
        (c.from === activeService && c.to === service.id) || 
        (c.to === activeService && c.from === service.id)
      )
      const isDimmed = activeService && !isActive && !isConnected

      // Glow for active
      if (isActive) {
        ctx.beginPath()
        ctx.arc(x, y, 35, 0, Math.PI * 2)
        ctx.fillStyle = service.color + '20'
        ctx.fill()
        ctx.shadowColor = service.color
        ctx.shadowBlur = 20
      }

      // Node circle
      ctx.beginPath()
      ctx.arc(x, y, 28, 0, Math.PI * 2)
      ctx.fillStyle = isDimmed ? '#1e293b' : '#0f172a'
      ctx.fill()
      ctx.strokeStyle = isDimmed ? '#334155' : service.color
      ctx.lineWidth = isActive ? 3 : 2
      ctx.stroke()
      ctx.shadowBlur = 0

      // Icon
      ctx.font = '16px sans-serif'
      ctx.fillStyle = isDimmed ? '#475569' : service.color
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillText(service.icon, x, y)

      // Label
      ctx.font = '11px sans-serif'
      ctx.fillStyle = isDimmed ? '#475569' : '#94a3b8'
      ctx.fillText(service.name, x, y + 42)
    })

  }, [animatedDots, activeService])

  return (
    <div className="space-y-4">
      <div className="relative bg-slate-950 rounded-lg border border-slate-800 overflow-hidden">
        <canvas
          ref={canvasRef}
          style={{ width: '100%', height: '500px' }}
          className="cursor-crosshair"
          onMouseMove={(e) => {
            const rect = e.currentTarget.getBoundingClientRect()
            const x = e.clientX - rect.left
            const y = e.clientY - rect.top
            const width = rect.width
            const height = rect.height

            // Find hovered service
            const hovered = services.find(s => {
              const sx = (s.x / 1200) * width
              const sy = (s.y / 500) * height
              const dist = Math.sqrt((x - sx) ** 2 + (y - sy) ** 2)
              return dist < 30
            })

            setActiveService(hovered?.id || null)
          }}
          onMouseLeave={() => setActiveService(null)}
        />
        
        {activeService && (
          <div className="absolute top-4 left-4 bg-slate-900/90 backdrop-blur-sm border border-slate-700 rounded-lg p-3 max-w-xs">
            {(() => {
              const service = services.find(s => s.id === activeService)
              if (!service) return null
              const serviceConns = connections.filter(c => c.from === activeService || c.to === activeService)
              return (
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span style={{ color: service.color }} className="text-lg">{service.icon}</span>
                    <h4 className="font-medium text-slate-200">{service.name}</h4>
                  </div>
                  <Badge variant="outline" style={{ borderColor: service.color + '40', color: service.color }}>
                    {service.category}
                  </Badge>
                  <div className="text-xs text-slate-400 space-y-1">
                    <p>Connections: {serviceConns.length}</p>
                    {serviceConns.map(c => (
                      <p key={`${c.from}-${c.to}`}>
                        {c.from === activeService ? '→' : '←'} {c.label}
                      </p>
                    ))}
                  </div>
                </div>
              )
            })()}
          </div>
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        {['Storage', 'API', 'Compute', 'Database', 'Event Bus', 'Orchestration', 'Notification', 'Tracing', 'Monitoring'].map(cat => {
          const catServices = services.filter(s => s.category === cat)
          const color = catServices[0]?.color || '#94a3b8'
          return (
            <Badge 
              key={cat} 
              variant="outline" 
              className="cursor-pointer hover:bg-slate-800"
              style={{ borderColor: color + '40', color }}
              onClick={() => setActiveService(activeService ? null : catServices[0]?.id || null)}
            >
              {cat}
            </Badge>
          )
        })}
      </div>
    </div>
  )
}
