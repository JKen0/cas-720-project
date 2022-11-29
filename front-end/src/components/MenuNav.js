import React, { useState } from 'react';
import { AppBar, AppBarSection, AppBarSpacer, Avatar, } from "@progress/kendo-react-layout";
import { Badge, BadgeContainer } from "@progress/kendo-react-indicators";
import { Link } from "react-router-dom";
import CreatePolicy from './CreatePolicy';
import ViewPolicy from './ViewPolicy';
import ViewPolicies from './ViewPolicies';
import ViewRequests from './ViewRequests';

const kendokaAvatar = "https://www.telerik.com/kendo-react-ui-develop/components/images/kendoka-react.png";

const MenuNavContainer = (props) => {
  const [currentView, setView] = useState("createpolicy");

  const viewRender = () => {
    switch(currentView) {
      case "createpolicy":
        return <CreatePolicy />;
      case "viewpolicy":
        return <ViewPolicy />;
      case "viewallpolicies":
        return <ViewPolicies />;
      case "viewallrequests":
        return <ViewRequests />;
      default:
        return <CreatePolicy />;

    }
  }



  return (
    <React.Fragment>
      <AppBar>
        <AppBarSection>
          <button className="k-button k-button-md k-rounded-md k-button-flat k-button-flat-base">
            <span className="k-icon k-i-menu" />
          </button>
        </AppBarSection>

        <AppBarSpacer
          style={{
            width: 4,
          }}
        />

        <AppBarSection>
          <h1 className="title">Crop Insurance Corp</h1>
        </AppBarSection>

        <AppBarSpacer
          style={{
            width: 32,
          }}
        />

        <AppBarSection>
          <ul>
            <li>
              <Link to="/createpolicy" onClick={() => setView("createpolicy")} >Create Policy</Link>
            </li>
            <li>
              <Link to="/viewpolicy" onClick={() => setView("viewpolicy")} >View Policy</Link>
            </li>
            <li>
              <Link to="/viewallpolicies" onClick={() => setView("viewallpolicies")}>View All Policies</Link>
            </li>
            <li>
              <Link to="/viewallrequests" onClick={() => setView("viewallrequests")}>View All Requests</Link>
            </li>
          </ul>
        </AppBarSection>

        <AppBarSpacer />

        <AppBarSection className="actions">
          <button className="k-button k-button-md k-rounded-md k-button-flat k-button-flat-base">
            <BadgeContainer>
              <span className="k-icon k-i-bell" />
              <Badge
                shape="dot"
                themeColor="info"
                size="small"
                position="inside"
              />
            </BadgeContainer>
          </button>
        </AppBarSection>

        <AppBarSection>
          <span className="k-appbar-separator" />
        </AppBarSection>

        <AppBarSection>
          <Avatar type="image">
            <img src={kendokaAvatar} />
          </Avatar>
        </AppBarSection>
      </AppBar>
      <style>{`
                body {
                    background: #dfdfdf;
                }
                .title {
                    font-size: 18px;
                    margin: 0;
                }
                ul {
                    font-size: 14px;
                    list-style-type: none;
                    padding: 0;
                    margin: 0;
                    display: flex;
                }
                li {
                    margin: 0 10px;
                }
                li:hover {
                    cursor: pointer;
                    color: #84cef1;
                }
                .k-button k-button-md k-rounded-md k-button-solid k-button-solid-base {
                    padding: 0;
                }
                .k-badge-container {
                    margin-right: 8px;
                }
            `}</style>

    {
      viewRender()
    }
      
    </React.Fragment>
  );
};
export default MenuNavContainer