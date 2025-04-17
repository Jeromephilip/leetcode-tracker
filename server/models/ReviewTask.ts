import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../db/sequelize';

interface ReviewTaskAttributes {
  id?: number;
  userId: string;
  problemId: string;
  reviewDate: Date;
  reviewed: boolean;
}

export class ReviewTask extends Model<ReviewTaskAttributes> implements ReviewTaskAttributes {
  id!: number;
  userId!: string;
  problemId!: string;
  reviewDate!: Date;
  reviewed!: boolean;
}

ReviewTask.init(
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    problemId: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    reviewDate: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    reviewed: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    sequelize,
    modelName: 'ReviewTask',
    tableName: 'review_tasks',
    timestamps: true
  }
);
