import { useQuery } from '@tanstack/react-query';
import { ReviewTask } from '../components/card/TasksCard';

const fetchDueReviews = async (): Promise<ReviewTask[]> => {
  const res = await fetch('http://localhost:4000/api/reviews/due', {
    method: 'GET',
    credentials: 'include'
  });

  if (!res.ok) throw new Error('Failed to fetch due reviews');
  return res.json();
};

export const useDueReviews = () => {
  return useQuery<ReviewTask[]>({
    queryKey: ['dueReviews'],
    queryFn: fetchDueReviews,
  });
};