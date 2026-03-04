package slowxml.test

import slowxml.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func testSelector() {
    let viewXml = """
    <UIContainer id="root_view">
        <AppBar title="Settings">
            <IconButton id="back_btn" class="icon primary" />
        </AppBar>

        <List class="settings-list">
            <ListItem class="item">
                <Text class="label">Wi-Fi</Text>
                <Status class="active">Connected</Status>
            </ListItem>

            <ListItem class="item disabled">
                <Text class="label">Bluetooth</Text>
                <Status>Off</Status>
            </ListItem>

            <Footer>
                <Text class="copyright">Version 1.0.0</Text>
            </Footer>
        </List>
    </UIContainer>
    """

    let root = XmlParser(viewXml).parse().getOrThrow()
    
    let backBtn = root.select("#back_btn")
    @Expect(backBtn?.attr("class"), "icon primary")

    let activeStatus = root.select(".settings-list .active")
    @Expect(activeStatus?.innerText, "Connected")

    let disabledItems = root.selectAll("ListItem.disabled")
    for (item in disabledItems) {
        @Expect(item.getElementsByTagName("Text")[0].innerText, "Bluetooth")
    }

    let version = root.select("List > Footer > Text")
    @Expect(version?.innerText, "Version 1.0.0")

    let allLabels = root.selectAll(".label")
    @Expect(allLabels.size, 2)
}

