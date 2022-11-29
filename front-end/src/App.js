import * as React from "react";
import { Routes, Route, Link } from "react-router-dom";
import "@progress/kendo-theme-default";
import CreatePolicy from './components/CreatePolicy';
import ViewPolicy from './components/ViewPolicy';
import MenuNavContainer from './components/MenuNav';


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
          <Route path="/viewpolicy" element={<ViewPolicy />} />
          <Route path="/viewallpolicies" element={<CreatePolicy />} />
          <Route path="/viewallrequests" element={<ViewPolicy />} />
          <Route path="*" element={<NoMatch />} />
        </Route>
      </Routes>
    </div>
  );
}

export default App;
