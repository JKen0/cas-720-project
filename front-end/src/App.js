import * as React from "react";
import { Routes, Route, Link } from "react-router-dom";
import "@progress/kendo-theme-default";
import CreatePolicy from './components/CreatePolicy';
import MyPolicies from './components/MyPolicies';
import MenuNavContainer from './components/MenuNav';
import ViewPolicies from "./components/ViewPolicies";
import ViewRequests from "./components/ViewRequests";


const App = () => {
  
  
  const NoMatch =() => {
    return (
      <div>
        <h2>Nothing to see here!</h2>
        <p>
          <Link to="/">Go to the home page</Link>
        </p>
      </div>
    );
  }


  return (
    <div>
      <Routes>
        <Route path="/" element={<MenuNavContainer />}>
          <Route index element={<CreatePolicy />} />
          <Route path="/createpolicy" element={<CreatePolicy />} />
          <Route path="/mypolicies" element={<MyPolicies />} />
          <Route path="/viewallpolicies" element={<ViewPolicies />} />
          <Route path="/viewallrequests" element={<ViewRequests />} />
          <Route path="*" element={<NoMatch />} />
        </Route>
      </Routes>
    </div>
  );
}

export default App;
