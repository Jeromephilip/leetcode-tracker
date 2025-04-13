import { RecentSubmissionsCard } from "./components/card/RecentSubmissionsCard";
import { TasksCard } from "./components/card/TasksCard";
import { useLeetcodeUserDetails } from "./hooks/useLeetcodeDetails";

const Dashboard = () => {
  const { data, isLoading } = useLeetcodeUserDetails("jerodahero");

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-2xl font-bold mb-6">📊 LeetCode Tracker</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <RecentSubmissionsCard data={data} isLoading={isLoading} />
          {/* Change this to add data from lambda */}
          <TasksCard data={data} isLoading={true} /> 
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
