// src/hooks/useDueReviews.ts
import { useQuery } from '@tanstack/react-query';

type ReviewResponse = {
  dueProblems: {
    problemId: string;
    previouslySolvedAt: string;
  }[];
};

const fetchDueReviews = async (): Promise<ReviewResponse> => {
  const res = await fetch('http://localhost:4000/api/reviews/due', {
    method: 'GET',
    credentials: 'include'
  });

  if (!res.ok) throw new Error('Failed to fetch due reviews');
  return res.json();
};

export const useDueReviews = () => {
  return useQuery<ReviewResponse>({
    queryKey: ['dueReviews'],
    queryFn: fetchDueReviews,
  });
};