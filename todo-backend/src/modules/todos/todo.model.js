const mongoose = require("mongoose");

const todoSchema = new mongoose.Schema(
  {
    ownerId: {
      type: String,
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    description: {
      type: String,
      trim: true,
      default:"",
      maxlength: 500,
    },
    completed: {
      type: Boolean,
      default: false,
    },
    dueAt: {
      type: Date,
      required: true,
    },
    priority: {
      type: String,
      enum: ["basic", "important", "urgent"],
      default: "basic",
    },
    reminderEnabled: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Todo", todoSchema);
