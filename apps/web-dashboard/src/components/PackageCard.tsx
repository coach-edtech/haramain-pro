import { Calendar, Users } from 'lucide-react'
import type { Rombongan } from '../types'

interface PackageCardProps {
  romongan: Rombongan
  onEdit?: (id: string) => void
}

const statusColors: Record<string, string> = {
  planned: 'bg-blue-100 text-blue-700',
  active: 'bg-green-100 text-green-700',
  completed: 'bg-gray-100 text-gray-700',
}

export default function PackageCard({ romongan, onEdit }: PackageCardProps) {
  return (
    <div className="card p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
            <Users className="w-6 h-6 text-primary-600" />
          </div>
          <div>
            <p className="font-medium text-gray-900">{romongan.name}</p>
            <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
              <span className="flex items-center gap-1">
                <Calendar className="w-4 h-4" />
                {romongan.start_date} - {romongan.end_date}
              </span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColors[romongan.status] || ''}`}>
            {romongan.status}
          </span>
          {onEdit && (
            <button 
              onClick={() => onEdit(romongan.id)}
              className="text-primary-600 hover:text-primary-700 text-sm font-medium"
            >
              Edit
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
