const Todo = require("./todo.model");

const priorities = ["basic", "important", "urgent"];

// const getTodos = async (req, res) => {
//   try {
//     const todos = await Todo.find().sort({ dueAt: 1, createdAt: -1 });
//     return res.status(200).json(todos);
//   } catch (error) {
//     return res.status(500).json({ error: error.message });
//   }
// };

const getTodos = async (req, res)=>{
  try{
    const ownerId = req.get("x-device-id");

    if(!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required",
      });
    }
    const todos = await Todo.find({ownerId}).sort({
      dueAt:1,
      createdAt:-1
    });
    return res.status(200).json(todos);
  }
  catch(error){
    return res.status(500).json({error:error.message});
  }
};

const createTodo = async (req, res) => {
  try {
    const ownerId = req.get("x-device-id");

    if (!ownerId) {
      return res.status(400).json({
        error: "x-device-id header is required",
      });
    }

    const { title, description, completed, dueAt, priority, reminderEnabled } = req.body;

    if (typeof title !== "string" || !title.trim()) {
      return res.status(400).json({ error: "Please provide a title" });
    }
    if (!dueAt || Number.isNaN(Date.parse(dueAt))) {
      return res.status(400).json({ error: "Please provide a valid due date and time" });
    }
    if (priority && !priorities.includes(priority)) {
      return res.status(400).json({ error: "Priority must be basic, important, or urgent" });
    }

    const todo = await Todo.create({
      ownerId,
      title: title.trim(),
      description: typeof description === "string" ? description.trim():"",
      completed: completed === true,
      dueAt: new Date(dueAt),
      priority: priority || "basic",
      reminderEnabled: reminderEnabled === true,
    });

    return res.status(201).json({ success: true, todo });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

const updateTodo = async (req, res) => {
  try {
    const ownerId =req.get("x-device-id");

    if (!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required"
      });
    }

    const updates = {};
    const { title, description, completed, dueAt, priority, reminderEnabled } = req.body;

    if (title !== undefined) {
      if (typeof title !== "string" || !title.trim()) {
        return res.status(400).json({ error: "Title cannot be empty" });
      }
      updates.title = title.trim();
    }
    if(description !== undefined){
      if(typeof description !== "string"){
        return res.status(400).json({error:"Description must be text"});
      }
      updates.description = description.trim();
    }
    if (completed !== undefined) {
      if (typeof completed !== "boolean") {
        return res.status(400).json({ error: "Completed must be true or false" });
      }
      updates.completed = completed;
    }
    if (dueAt !== undefined) {
      if (!dueAt || Number.isNaN(Date.parse(dueAt))) {
        return res.status(400).json({ error: "Please provide a valid due date and time" });
      }
      updates.dueAt = new Date(dueAt);
    }
    if (priority !== undefined) {
      if (!priorities.includes(priority)) {
        return res.status(400).json({ error: "Priority must be basic, important, or urgent" });
      }
      updates.priority = priority;
    }
    if (reminderEnabled !== undefined) {
      if (typeof reminderEnabled !== "boolean") {
        return res.status(400).json({ error: "Reminder enabled must be true or false" });
      }
      updates.reminderEnabled = reminderEnabled;
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: "Provide at least one field to update" });
    }

    const todo = await Todo.findOneAndUpdate({_id:req.params.id, ownerId}, updates, {
      new: true,
      runValidators: true,
    });
    if (!todo) {
      return res.status(404).json({ error: "Todo not found" });
    }

    return res.status(200).json({ success: true, todo });
  } catch (error) {
    const status = error.name === "CastError" ? 400 : 500;
    return res.status(status).json({ error: error.message });
  }
};

const deleteTodo = async (req, res) => {
  try {
    const ownerId =req.get("x-device-id");

    if(!ownerId){
      return res.status(400).json({
        error:"x-device-id header is required",
      });
    }
    const todo = await Todo.findOneAndDelete({_id:req.params.id, ownerId});
    if (!todo) {
      return res.status(404).json({ error: "Todo not found" });
    }
    return res.status(200).json({ success: true, todo });
  } catch (error) {
    const status = error.name === "CastError" ? 400 : 500;
    return res.status(status).json({ error: error.message });
  }
};

module.exports = { getTodos, createTodo, updateTodo, deleteTodo };
