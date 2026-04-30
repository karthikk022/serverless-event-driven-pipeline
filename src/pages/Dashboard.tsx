import { useState } from 'react'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import ArchitectureDiagram from '@/components/ArchitectureDiagram'
import EventTriggerPanel from '@/components/EventTriggerPanel'
import PipelineMonitor from '@/components/PipelineMonitor'
import { Activity, Layers, Zap, Settings, GitBranch, Radio } from 'lucide-react'

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('architecture')

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="relative">
                <div className="absolute inset-0 bg-blue-500 rounded-lg blur-sm opacity-40"></div>
                <Layers className="w-8 h-8 text-blue-400 relative" />
              </div>
              <div>
                <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
                  Serverless Event Pipeline
                </h1>
                <p className="text-xs text-slate-400">AWS Lambda · EventBridge · Step Functions · X-Ray</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="outline" className="border-green-500/50 text-green-400 bg-green-500/10">
                <Radio className="w-3 h-3 mr-1" /> Active
              </Badge>
              <Badge variant="outline" className="border-slate-700 text-slate-400">
                Terraform IaC
              </Badge>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="bg-slate-900 border border-slate-800 p-1">
            <TabsTrigger value="architecture" className="data-[state=active]:bg-slate-800 data-[state=active]:text-blue-400">
              <GitBranch className="w-4 h-4 mr-2" />
              Architecture
            </TabsTrigger>
            <TabsTrigger value="triggers" className="data-[state=active]:bg-slate-800 data-[state=active]:text-amber-400">
              <Zap className="w-4 h-4 mr-2" />
              Event Triggers
            </TabsTrigger>
            <TabsTrigger value="monitor" className="data-[state=active]:bg-slate-800 data-[state=active]:text-emerald-400">
              <Activity className="w-4 h-4 mr-2" />
              Pipeline Monitor
            </TabsTrigger>
            <TabsTrigger value="config" className="data-[state=active]:bg-slate-800 data-[state=active]:text-purple-400">
              <Settings className="w-4 h-4 mr-2" />
              Infrastructure
            </TabsTrigger>
          </TabsList>

          <TabsContent value="architecture" className="space-y-6">
            <Card className="bg-slate-900 border-slate-800">
              <CardHeader>
                <CardTitle className="text-slate-100">System Architecture</CardTitle>
                <CardDescription className="text-slate-400">
                  Event-driven serverless pipeline with S3, DynamoDB Streams, EventBridge, and Step Functions
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ArchitectureDiagram />
              </CardContent>
            </Card>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card className="bg-slate-900 border-slate-800">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm text-slate-300">Ingestion Layer</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <ul className="space-y-2 text-sm text-slate-400">
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-amber-400"></span>
                      S3 Image Upload Events
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-amber-400"></span>
                      API Gateway REST Endpoints
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-amber-400"></span>
                      DynamoDB Stream Changes
                    </li>
                  </ul>
                </CardContent>
              </Card>

              <Card className="bg-slate-900 border-slate-800">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm text-slate-300">Processing Layer</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <ul className="space-y-2 text-sm text-slate-400">
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-blue-400"></span>
                      Lambda S3 Processor
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-blue-400"></span>
                      Lambda Stream Processor
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-blue-400"></span>
                      Step Functions Orchestrator
                    </li>
                  </ul>
                </CardContent>
              </Card>

              <Card className="bg-slate-900 border-slate-800">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm text-slate-300">Routing Layer</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <ul className="space-y-2 text-sm text-slate-400">
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-purple-400"></span>
                      EventBridge Custom Bus
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-purple-400"></span>
                      Multiple Event Targets
                    </li>
                    <li className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-purple-400"></span>
                      Archive & Replay
                    </li>
                  </ul>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          <TabsContent value="triggers">
            <EventTriggerPanel />
          </TabsContent>

          <TabsContent value="monitor">
            <PipelineMonitor />
          </TabsContent>

          <TabsContent value="config" className="space-y-6">
            <Card className="bg-slate-900 border-slate-800">
              <CardHeader>
                <CardTitle className="text-slate-100">Terraform Infrastructure</CardTitle>
                <CardDescription className="text-slate-400">
                  Infrastructure as Code configuration for all AWS resources
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <h4 className="text-sm font-medium text-slate-300">Compute</h4>
                    <Separator className="bg-slate-800" />
                    <div className="space-y-1 text-sm text-slate-400">
                      <p>10 Lambda Functions (Python 3.11 + Node.js 20)</p>
                      <p>X-Ray Active Tracing Enabled</p>
                      <p>Dead Letter Queues (SQS)</p>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-medium text-slate-300">Orchestration</h4>
                    <Separator className="bg-slate-800" />
                    <div className="space-y-1 text-sm text-slate-400">
                      <p>Step Functions Express Workflows</p>
                      <p>Parallel Processing Branches</p>
                      <p>Error Handling & Retries</p>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-medium text-slate-300">Event Routing</h4>
                    <Separator className="bg-slate-800" />
                    <div className="space-y-1 text-sm text-slate-400">
                      <p>EventBridge Custom Event Bus</p>
                      <p>3 Event Rules with Pattern Matching</p>
                      <p>SNS + Lambda + Step Functions Targets</p>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="text-sm font-medium text-slate-300">Storage</h4>
                    <Separator className="bg-slate-800" />
                    <div className="space-y-1 text-sm text-slate-400">
                      <p>S3 Buckets (Images, Processed, DLQ)</p>
                      <p>DynamoDB with Streams</p>
                      <p>GSI for Query Patterns</p>
                    </div>
                  </div>
                </div>

                <Separator className="bg-slate-800" />

                <div className="bg-slate-950 rounded-lg p-4 border border-slate-800">
                  <h4 className="text-sm font-medium text-slate-300 mb-2">Deployment Commands</h4>
                  <pre className="text-xs text-green-400 overflow-x-auto">
{`# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -var="environment=dev"

# Apply infrastructure
terraform apply -var="environment=dev"

# Deploy Lambda code
./scripts/deploy-lambdas.sh

# Verify deployment
terraform output`}
                  </pre>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  )
}
