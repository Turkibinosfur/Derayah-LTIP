import { useMemo } from 'react';
import { Clock, TrendingUp, Zap } from 'lucide-react';

interface VestingMilestone {
  milestone_type: 'time' | 'performance' | 'hybrid';
  sequence_order: number;
  vesting_percentage: number;
  months_from_start: number | null;
  performance_metric_id: string | null;
  target_value: number | null;
}

interface VestingTimelineProps {
  milestones: VestingMilestone[];
  totalMonths: number;
  onMilestoneClick?: (index: number) => void;
  onMilestoneDrag?: (fromIndex: number, toIndex: number) => void;
}

export default function VestingTimeline({
  milestones,
  totalMonths,
  onMilestoneClick,
  onMilestoneDrag
}: VestingTimelineProps) {
  const sortedMilestones = useMemo(() => {
    return [...milestones].sort((a, b) => {
      const aMonths = a.months_from_start || 0;
      const bMonths = b.months_from_start || 0;
      return aMonths - bMonths;
    });
  }, [milestones]);

  const cumulativePercentages = useMemo(() => {
    let cumulative = 0;
    return sortedMilestones.map(m => {
      cumulative += m.vesting_percentage;
      return cumulative;
    });
  }, [sortedMilestones]);

  const getMilestoneIcon = (type: string) => {
    switch (type) {
      case 'time': return <Clock className="w-4 h-4" />;
      case 'performance': return <TrendingUp className="w-4 h-4" />;
      case 'hybrid': return <Zap className="w-4 h-4" />;
      default: return <Clock className="w-4 h-4" />;
    }
  };

  const getMilestoneColor = (type: string) => {
    switch (type) {
      case 'time': return 'bg-blue-500';
      case 'performance': return 'bg-green-500';
      case 'hybrid': return 'bg-purple-500';
      default: return 'bg-gray-500';
    }
  };

  if (sortedMilestones.length === 0) {
    return (
      <div className="bg-gray-50 rounded-lg p-8 text-center">
        <p className="text-gray-500">No milestones to display</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Vesting Timeline</h3>
        <p className="text-sm text-gray-600">Visual representation of vesting progression over time</p>
      </div>

      <div className="relative">
        <div className="absolute left-0 top-4 w-full h-2 bg-gray-200 rounded-full" />

        <div className="relative flex items-start justify-between" style={{ minHeight: '200px' }}>
          {sortedMilestones.map((milestone, index) => {
            const position = totalMonths > 0 && milestone.months_from_start !== null
              ? (milestone.months_from_start / totalMonths) * 100
              : (index / (sortedMilestones.length - 1 || 1)) * 100;

            return (
              <div
                key={index}
                className="absolute flex flex-col items-center"
                style={{ left: `${position}%`, transform: 'translateX(-50%)' }}
              >
                <button
                  onClick={() => onMilestoneClick?.(milestone.sequence_order)}
                  className={`w-8 h-8 rounded-full ${getMilestoneColor(milestone.milestone_type)}
                    flex items-center justify-center text-white shadow-lg hover:scale-110
                    transition-transform cursor-pointer z-10 relative`}
                  title={`${milestone.vesting_percentage}% vests`}
                >
                  {getMilestoneIcon(milestone.milestone_type)}
                </button>

                <div className="mt-4 text-center">
                  <div className="bg-white border border-gray-200 rounded-lg p-2 shadow-sm min-w-[100px]">
                    <div className="text-xs font-semibold text-gray-900">
                      {milestone.vesting_percentage.toFixed(1)}%
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {milestone.months_from_start !== null
                        ? `Month ${milestone.months_from_start}`
                        : 'Performance'}
                    </div>
                    <div className="text-xs text-gray-400 mt-1">
                      Total: {cumulativePercentages[index].toFixed(1)}%
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="mt-24 pt-4 border-t border-gray-200">
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>Start (Month 0)</span>
            <span>End (Month {totalMonths})</span>
          </div>
        </div>
      </div>

      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className="grid grid-cols-3 gap-4 text-sm">
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
              <Clock className="w-3 h-3 text-white" />
            </div>
            <span className="text-gray-600">Time-Based</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-green-500 rounded-full flex items-center justify-center">
              <TrendingUp className="w-3 h-3 text-white" />
            </div>
            <span className="text-gray-600">Performance</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-purple-500 rounded-full flex items-center justify-center">
              <Zap className="w-3 h-3 text-white" />
            </div>
            <span className="text-gray-600">Hybrid</span>
          </div>
        </div>
      </div>
    </div>
  );
}
