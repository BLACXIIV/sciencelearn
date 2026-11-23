import { Route, Routes } from "react-router-dom";
import RequireTeacher from "./components/RequireTeacher";
import AppLayout from "./components/AppLayout";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import ManageLessons from "./pages/ManageLessons";

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<RequireTeacher />}>
        <Route element={<AppLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="lessons" element={<ManageLessons />} />
        </Route>
      </Route>
    </Routes>
  );
}
