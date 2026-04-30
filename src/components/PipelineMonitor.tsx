import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Activity, CheckCircle, XCircle, Clock, AlertTriangle, TrendingUp, Server, Zap } from 'lucide-react'

interface Execution {
  id: string
  status: 'running' | 'succeeded' | 'failed' | 'timed_out'
  startTime: string
  endTime?: string
  steps: Step[]
  duration: number
}

interface Step {
  name: string
  status: 'pending' | 'running' | 'succeeded' | 'failed'
  duration: number
}

const mockExecutions: Execution[] = [
  {
    id: 'exec-001',
    status: 'succeeded',
    startTime: '2024-01-15T10:30:00Z',
    endTime: '2024-01-15T10:30:04Z',
    duration: 4200,
    steps: [
      { name: 'ValidateInput', status: 'succeeded', duration: 800 },
      { name: 'TransformData', status: 'succeeded', duration: 1200 },
      { name: 'EnrichData', status: 'succeeded', duration: 900 },
      { name: 'MergeResults', status: 'succeeded', duration: 600 },
      { name: 'NotifyCompletion', status: 'succeeded', duration: 700 },
    ]
  },
  {
    id: 'exec-002',
    status: 'running',
    startTime: '2024-01-15T10:31:00Z',
    duration: 2100,
    steps: [
      { name: 'ValidateInput', status: 'succeeded', duration: 750 },
      { name: 'TransformData', status: 'running', duration: 1350 },
      { name: 'EnrichData', status: 'pending', duration: 0 },
      { name: 'MergeResults', status: 'pending', duration: 0 },
      { name: 'NotifyCompletion', status: 'pending', duration: 0 },
    ]
  },
  {
    id: 'exec-003',
    status: 'failed',
    startTime: '2024-01-15T10:25:00Z',
    endTime: '2024-01-15T10:25:03Z',
    duration: 3100,
    steps: [
      { name: 'ValidateInput', status: 'succeeded', duration: 900 },
      { name: 'TransformData', status: 'failed', duration: 2200 },
      { name: 'EnrichData', status: 'pending', duration: 0 },
      { name: 'MergeResults', status: 'pending', duration: 0 },
      { name: 'NotifyCompletion', status: 'pending', duration: 0 },
    ]
  }
]

const mockMetrics = {
  totalExecutions: 156,
  succeeded: 142,
  failed: 8,
  running: 6,
  avgDuration: 3.2,
  lambdaInvocations: 1248,
  eventsProcessed: 893
}

export default function PipelineMonitor() {
  const [executions, setExecutions] = useState<Execution[]>(mockExecutions)
  const [metrics, setMetrics] = useState(mockMetrics)

  // Simulate live updates
  useEffect(() => {
    const interval = setInterval(() => {
      setExecutions(prev => prev.map(ex => {
        if (ex.status === 'running') {
          return {
            ...ex,
            duration: ex.duration + 500,
            steps: ex.steps.map((step, idx) => {
              if (step.status === 'running' && Math.random() > 0.7) {
                return { ...step, status: 'succeeded' as const, duration: step.duration + 500 }
              }
              if (step.status === 'pending' && ex.steps[idx - 1]?.status === 'succeeded') {
                return { ...step, status: 'running' as const, duration: 500 }
              }
              return step
            })
          }
        }
        return ex
      }))

      setMetrics(prev => ({
        ...prev,
        lambdaInvocations: prev.lambdaInvocations + Math.floor(Math.random() * 3),
        eventsProcessed: prev.eventsProcessed + Math.floor(Math.random() * 2)
      }))
    }, 2000)

    return () => clearInterval(interval)
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'succeeded': return 'bg-green-500/10 text-green-400 border-green-500/30'
      case 'failed': return 'bg-red-500/10 text-red-400 border-red-500/30'
      case 'running': return 'bg-blue-500/10 text-blue-400 border-blue-500/30'
      case 'timed_out': return 'bg-amber-500/10 text-amber-400 border-amber-500/30'
      default: return 'bg-slate-500/10 text-slate-400 border-slate-500/30'
    }
  }

  const getStepIcon = (status: string) => {
    switch (status) {
      case 'succeeded': return <CheckCircle className="w-4 h-4 text-green-400" />
      case 'failed': return <XCircle className="w-4 h-4 text-red-400" />
      case 'running': return <Activity className="w-4 h-4 text-blue-400 animate-pulse" />
      default: return <Clock className="w-4 h-4 text-slate-500" />
    }
  }

  return (
    <div className="space-y-6">
      {/* Metrics Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="bg-slate-900 border-slate-800">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-400">Total Executions</p>
                <p className="text-2xl font-bold text-slate-100">{metrics.totalExecutions}</p>
              </div>
              <Server className="w-8 h-8 text-blue-400 opacity-50" />
            </div>
            <div className="mt-2 flex gap-1">
              <Badge variant="outline" className="bg-green-500/10 text-green-400 border-green-500/30 text-xs">
                {metrics.succeeded} OK
              </Badge>
              <Badge variant="outline" className="bg-red-500/10 text-red-400 border-red-500/30 text-xs">
                {metrics.failed} Fail
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-800">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-400">Lambda Invocations</p>
                <p className="text-2xl font-bold text-slate-100">{metrics.lambdaInvocations.toLocaleString()}</p>
              </div>
              <Zap className="w-8 h-8 text-amber-400 opacity-50" />
            </div>
            <div className="mt-2">
              <Badge variant="outline" className="bg-amber-500/10 text-amber-400 border-amber-500/30 text-xs">
                <TrendingUp className="w-3 h-3 mr-1" />
                +12% vs last hour
              </Badge>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-800">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-400">Events Processed</p>
                <p className="text-2xl font-bold text-slate-100">{metrics.eventsProcessed.toLocaleString()}</p>
              </div>
              <Activity className="w-8 h-8 text-purple-400 opacity-50" />
            </div>
            <div className="mt-2 text-xs text-slate-500">
              Avg {Math.round(metrics.eventsProcessed / 24)}/hour
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-800">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-400">Avg Duration</p>
                <p className="text-2xl font-bold text-slate-100">{metrics.avgDuration}s</p>
              </div>
              <Clock className="w-8 h-8 text-cyan-400 opacity-50" />
            </div>
            <div className="mt-2 text-xs text-slate-500">
              p99: 5.8s
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Success Rate */}
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader className="pb-2">
          <CardTitle className="text-slate-100 text-base">Success Rate</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-slate-400">Overall</span>
                <span className="text-green-400">{((metrics.succeeded / metrics.totalExecutions) * 100).toFixed(1)}%</span>
              </div>
              <Progress value={(metrics.succeeded / metrics.totalExecutions) * 100} className="h-2 bg-slate-800" />
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-slate-400">This Hour</span>
                <span className="text-green-400">94.2%</span>
              </div>
              <Progress value={94.2} className="h-2 bg-slate-800" />
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-slate-400">Last 24h</span>
                <span className="text-green-400">91.0%</span>
              </div>
              <Progress value={91} className="h-2 bg-slate-800" />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Executions List */}
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle className="text-slate-100 text-base">Recent Executions</CardTitle>
          <CardDescription className="text-slate-400">
            Step Functions workflow execution history
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {executions.map(exec => (
            <div key={exec.id} className={`border rounded-lg p-4 ${getStatusColor(exec.status)}`}>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  {exec.status === 'succeeded' ? <CheckCircle className="w-5 h-5 text-green-400" /> :
                   exec.status === 'failed' ? <XCircle className="w-5 h-5 text-red-400" /> :
                   <Activity className="w-5 h-5 text-blue-400 animate-pulse" />}
                  <span className="font-medium">{exec.id}</span>
                  <Badge variant="outline" className="text-xs">
                    {exec.status}
                  </Badge>
                </div>
                <span className="text-xs opacity-70">
                  {(exec.duration / 1000).toFixed(1)}s
                </span>
              </div>

              {/* Steps Timeline */}
              <div className="flex items-center gap-1">
                {exec.steps.map((step, idx) => (
                  <div key={step.name} className="flex items-center flex-1">
                    <div className="flex flex-col items-center flex-1">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                        step.status === 'succeeded' ? 'border-green-500 bg-green-500/20' :
                        step.status === 'running' ? 'border-blue-500 bg-blue-500/20' :
                        step.status === 'failed' ? 'border-red-500 bg-red-500/20' :
                        'border-slate-600 bg-slate-800'
                      }`}>
                        {getStepIcon(step.status)}
                      </div>
                      <span className="text-xs mt-1 opacity-70">{step.name}</span>
                      <span className="text-xs opacity-50">{(step.duration / 1000).toFixed(1)}s</span>
                    </div>
                    {idx < exec.steps.length - 1 && (
                      <div className={`h-0.5 flex-1 mx-1 ${
                        step.status === 'succeeded' ? 'bg-green-500/50' : 'bg-slate-700'
                      }`} />
                    )}
                  </div>
                ))}
              </div>

              {exec.status === 'failed' && (
                <div className="mt-3 flex items-center gap-2 text-sm text-red-400">
                  <AlertTriangle className="w-4 h-4" />
                  <span>TransformData failed: Lambda timeout after 3s</span>
                </div>
              )}
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Lambda Functions Status */}
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle className="text-slate-100 text-base">Lambda Functions</CardTitle>
          <CardDescription className="text-slate-400">
            Health status of all Lambda functions
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
            {[
              { name: 'S3 Processor', invocations: 342, errors: 2, color: 'amber' },
              { name: 'API Handler', invocations: 891, errors: 0, color: 'purple' },
              { name: 'Stream Processor', invocations: 342, errors: 1, color: 'cyan' },
              { name: 'Event Processor', invocations: 156, errors: 3, color: 'violet' },
              { name: 'Step Validate', invocations: 156, errors: 0, color: 'blue' },
              { name: 'Step Transform', invocations: 156, errors: 2, color: 'blue' },
              { name: 'Step Enrich', invocations: 148, errors: 0, color: 'blue' },
              { name: 'Step Notify', invocations: 142, errors: 1, color: 'blue' },
              { name: 'DLQ Handler', invocations: 12, errors: 0, color: 'red' },
            ].map(fn => (
              <div key={fn.name} className="bg-slate-950 rounded-lg p-3 border border-slate-800">
                <div className="flex items-center gap-2 mb-2">
                  <div className={`w-2 h-2 rounded-full bg-${fn.color}-400`}></div>
                  <span className="text-xs font-medium text-slate-300">{fn.name}</span>
                </div>
                <div className="text-xs text-slate-500 space-y-1">
                  <p>Inv: {fn.invocations.toLocaleString()}</p>
                  <p className={fn.errors > 0 ? 'text-red-400' : 'text-green-400'}>
                    Err: {fn.errors} ({((fn.errors / fn.invocations) * 100).toFixed(1)}%)
                  </p>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
