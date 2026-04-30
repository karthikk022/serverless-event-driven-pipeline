import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Upload, Send, FileImage, Workflow, CheckCircle, AlertCircle, Clock } from 'lucide-react'

interface TriggerEvent {
  id: string
  type: string
  status: 'pending' | 'sent' | 'success' | 'error'
  timestamp: string
  payload: string
}

export default function EventTriggerPanel() {
  const [events, setEvents] = useState<TriggerEvent[]>([])
  const [imageFilename, setImageFilename] = useState('test-image.jpg')
  const [eventPayload, setEventPayload] = useState(JSON.stringify({
    eventType: 'TEST_EVENT',
    payload: { message: 'Hello from test trigger' }
  }, null, 2))
  const [pipelineInput, setPipelineInput] = useState(JSON.stringify({
    imageId: 'test-123',
    action: 'process',
    priority: 'high'
  }, null, 2))

  const addEvent = (type: string, payload: string) => {
    const newEvent: TriggerEvent = {
      id: `evt-${Date.now()}`,
      type,
      status: 'sent',
      timestamp: new Date().toISOString(),
      payload
    }
    setEvents(prev => [newEvent, ...prev])

    // Simulate status changes
    setTimeout(() => {
      setEvents(prev => prev.map(e => 
        e.id === newEvent.id ? { ...e, status: 'success' } : e
      ))
    }, 2000)
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success': return <CheckCircle className="w-4 h-4 text-green-400" />
      case 'error': return <AlertCircle className="w-4 h-4 text-red-400" />
      case 'sent': return <Clock className="w-4 h-4 text-amber-400" />
      default: return <Clock className="w-4 h-4 text-slate-400" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success': return 'bg-green-500/10 text-green-400 border-green-500/30'
      case 'error': return 'bg-red-500/10 text-red-400 border-red-500/30'
      case 'sent': return 'bg-amber-500/10 text-amber-400 border-amber-500/30'
      default: return 'bg-slate-500/10 text-slate-400 border-slate-500/30'
    }
  }

  return (
    <div className="space-y-6">
      <Tabs defaultValue="s3" className="space-y-4">
        <TabsList className="bg-slate-900 border border-slate-800">
          <TabsTrigger value="s3" className="data-[state=active]:bg-slate-800 data-[state=active]:text-amber-400">
            <FileImage className="w-4 h-4 mr-2" />
            S3 Upload
          </TabsTrigger>
          <TabsTrigger value="eventbridge" className="data-[state=active]:bg-slate-800 data-[state=active]:text-purple-400">
            <Send className="w-4 h-4 mr-2" />
            EventBridge
          </TabsTrigger>
          <TabsTrigger value="pipeline" className="data-[state=active]:bg-slate-800 data-[state=active]:text-red-400">
            <Workflow className="w-4 h-4 mr-2" />
            Step Functions
          </TabsTrigger>
        </TabsList>

        <TabsContent value="s3" className="space-y-4">
          <Card className="bg-slate-900 border-slate-800">
            <CardHeader>
              <CardTitle className="text-slate-100 text-base">Simulate S3 Image Upload</CardTitle>
              <CardDescription className="text-slate-400">
                Trigger the S3 processor Lambda by simulating an image upload event
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-slate-400">Image Filename</label>
                <div className="flex gap-2">
                  <Input 
                    value={imageFilename}
                    onChange={(e) => setImageFilename(e.target.value)}
                    className="bg-slate-950 border-slate-700 text-slate-200"
                    placeholder="image.jpg"
                  />
                  <Button 
                    onClick={() => addEvent('S3_UPLOAD', JSON.stringify({ key: `uploads/${imageFilename}` }))}
                    className="bg-amber-600 hover:bg-amber-700 text-white"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Trigger
                  </Button>
                </div>
              </div>

              <div className="bg-slate-950 rounded-lg p-3 border border-slate-800">
                <h4 className="text-xs font-medium text-slate-500 mb-2">What happens:</h4>
                <ol className="text-sm text-slate-400 space-y-1 list-decimal list-inside">
                  <li>S3 event notification fires</li>
                  <li>Lambda S3 Processor executes</li>
                  <li>Metadata stored in DynamoDB</li>
                  <li>EventBridge event emitted</li>
                  <li>DynamoDB Stream triggers downstream</li>
                </ol>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="eventbridge" className="space-y-4">
          <Card className="bg-slate-900 border-slate-800">
            <CardHeader>
              <CardTitle className="text-slate-100 text-base">Send EventBridge Event</CardTitle>
              <CardDescription className="text-slate-400">
                Publish a custom event to the EventBridge event bus
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-slate-400">Event Payload (JSON)</label>
                <Textarea 
                  value={eventPayload}
                  onChange={(e) => setEventPayload(e.target.value)}
                  className="bg-slate-950 border-slate-700 text-slate-200 font-mono text-xs min-h-[120px]"
                />
                <Button 
                  onClick={() => addEvent('EVENTBRIDGE', eventPayload)}
                  className="bg-purple-600 hover:bg-purple-700 text-white w-full"
                >
                  <Send className="w-4 h-4 mr-2" />
                  Publish Event
                </Button>
              </div>

              <div className="bg-slate-950 rounded-lg p-3 border border-slate-800">
                <h4 className="text-xs font-medium text-slate-500 mb-2">Routing Rules:</h4>
                <ul className="text-sm text-slate-400 space-y-1">
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-purple-400"></span>
                    ImageProcessed → Lambda Processor
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-purple-400"></span>
                    PipelineTriggered → Step Functions
                  </li>
                  <li className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-purple-400"></span>
                    All Events → SNS + Archive
                  </li>
                </ul>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="pipeline" className="space-y-4">
          <Card className="bg-slate-900 border-slate-800">
            <CardHeader>
              <CardTitle className="text-slate-100 text-base">Trigger Step Functions</CardTitle>
              <CardDescription className="text-slate-400">
                Start a new Step Functions workflow execution
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm text-slate-400">Execution Input (JSON)</label>
                <Textarea 
                  value={pipelineInput}
                  onChange={(e) => setPipelineInput(e.target.value)}
                  className="bg-slate-950 border-slate-700 text-slate-200 font-mono text-xs min-h-[120px]"
                />
                <Button 
                  onClick={() => addEvent('STEP_FUNCTIONS', pipelineInput)}
                  className="bg-red-600 hover:bg-red-700 text-white w-full"
                >
                  <Workflow className="w-4 h-4 mr-2" />
                  Start Execution
                </Button>
              </div>

              <div className="bg-slate-950 rounded-lg p-3 border border-slate-800">
                <h4 className="text-xs font-medium text-slate-500 mb-2">Workflow Steps:</h4>
                <ol className="text-sm text-slate-400 space-y-1 list-decimal list-inside">
                  <li>Validate Input</li>
                  <li>Parallel Transform + Enrich</li>
                  <li>Merge Results</li>
                  <li>Send Notification</li>
                  <li>Emit Completion Event</li>
                </ol>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Event Log */}
      <Card className="bg-slate-900 border-slate-800">
        <CardHeader>
          <CardTitle className="text-slate-100 text-base">Event Log</CardTitle>
          <CardDescription className="text-slate-400">
            Recent triggered events and their status
          </CardDescription>
        </CardHeader>
        <CardContent>
          {events.length === 0 ? (
            <p className="text-sm text-slate-500 text-center py-8">No events triggered yet. Use the panels above to send events.</p>
          ) : (
            <div className="space-y-2 max-h-[400px] overflow-y-auto">
              {events.map(event => (
                <div key={event.id} className={`flex items-center gap-3 p-3 rounded-lg border ${getStatusColor(event.status)}`}>
                  {getStatusIcon(event.status)}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-sm">{event.type}</span>
                      <span className="text-xs opacity-70">{event.id}</span>
                    </div>
                    <p className="text-xs opacity-70 truncate">{event.payload}</p>
                  </div>
                  <span className="text-xs opacity-70">
                    {new Date(event.timestamp).toLocaleTimeString()}
                  </span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
