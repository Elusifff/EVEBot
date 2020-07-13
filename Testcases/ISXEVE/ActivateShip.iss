#define TESTCASE 1

#include Scripts/EVEBot/Support/TestAPI.iss
/*
 *	Test GetHangarItems
 *
 *  Revision $Id$
 *
 *	Requirements:
 *		Docked
 *		Have items in station hangar
 *
 */


function main()
	{
		variable index:item hsIndex
		variable iterator hsIterator
		UI:UpdateConsole["Step-1"]
		;if ${Station.Docked}
		{
		UI:UpdateConsole["Step0"]
			EVE:Execute[OpenShipHangar]
			Me.Station:GetHangarShips[hsIndex]
			hsIndex:GetIterator[hsIterator]

			{
			UI:UpdateConsole["Step1"]
				if ${hsIterator:First(exists)}
				{
				UI:UpdateConsole["Step2"]
					do
					{
						{
							UI:UpdateConsole["obj_Ship: Switching to ship named ${hsIterator.Value.Name}."]
							hsIterator.Value:MakeActive
							break
						}
					}
					while ${hsIterator:Next(exists)}
				}
			}
		}

}