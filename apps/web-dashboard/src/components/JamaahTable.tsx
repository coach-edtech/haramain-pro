import { Mail, Phone, Shield } from 'lucide-react'
import type { Profile } from '../types'

interface JamaahTableProps {
  jamaah: Profile[]
}

const tierColors = {
  trial: 'bg-gray-100 text-gray-700',
  active: 'bg-green-100 text-green-700',
  expired: 'bg-red-100 text-red-700',
}

export default function JamaahTable({ jamaah }: JamaahTableProps) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Subscription</th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {jamaah.map((person) => (
            <tr key={person.id} className="hover:bg-gray-50">
              <td className="px-4 py-3">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                    <span className="text-primary-700 font-medium text-sm">
                      {person.name[0].toUpperCase()}
                    </span>
                  </div>
                  <span className="font-medium text-gray-900">{person.name}</span>
                </div>
              </td>
              <td className="px-4 py-3 text-gray-600">{person.email}</td>
              <td className="px-4 py-3">
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${tierColors[person.subscription_tier]}`}>
                  {person.subscription_tier}
                </span>
              </td>
              <td className="px-4 py-3">
                <div className="flex items-center gap-2">
                  <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                    <Mail className="w-4 h-4" />
                  </button>
                  <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                    <Phone className="w-4 h-4" />
                  </button>
                  <button className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded">
                    <Shield className="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}