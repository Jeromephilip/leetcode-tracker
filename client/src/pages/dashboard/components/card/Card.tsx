import React from "react";

interface CardProps {
  title: string;
  isLoading: boolean;
  loadingText?: string;
  children: React.ReactNode;
}

export const Card = ({ title, isLoading, loadingText, children }: CardProps) => {
  return (
    <div className="bg-white p-4 rounded shadow">
      <h2 className="text-lg font-bold mb-2">{title}</h2>
      {isLoading ? (
        <p className="text-gray-500">{loadingText || "Loading..."}</p>
      ) : (
        <div className="max-h-[300px] overflow-y-auto">{children}</div>
      )}
    </div>
  );
};