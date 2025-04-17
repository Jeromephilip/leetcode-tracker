import { Card } from "./Card";
import { UserProfile } from "leetcode-query";

interface RecentSubmissionsCardProps {
  data?: UserProfile;
  isLoading: boolean;
}

export const RecentSubmissionsCard = ({
  data,
  isLoading,
}: RecentSubmissionsCardProps) => {
  const acceptedSubmissions = data?.recentSubmissionList?.filter(
    (submission) => submission.statusDisplay === "Accepted"
  );

  return (
    <Card
      title="Recent Submissions"
      isLoading={isLoading}
      loadingText="Loading submissions..."
    >
      <div className="space-y-4">
        {acceptedSubmissions && acceptedSubmissions.length > 0 ? (
          acceptedSubmissions.map((submission, index) => (
            <div
              key={`submission-${submission.title}-${index}`}
              className="mb-4 flex items-center justify-between gap-4"
            >
              <div>
                <p className="font-semibold text-black">{submission.title}</p>
                <p className="text-gray-500">Status: {submission.statusDisplay}</p>
              </div>
            </div>
          ))
        ) : (
          <p className="text-sm text-gray-400 text-center">No accepted submissions yet</p>
        )}
      </div>
    </Card>
  );
};
